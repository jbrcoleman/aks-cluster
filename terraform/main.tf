# terraform/main.tf

# Create required providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
  
  backend "azurerm" {
    # These values should be configured through backend configuration file
    # resource_group_name  = "terraform-state-rg"
    # storage_account_name = "terraformstatesa"
    # container_name       = "terraform-state"
    # key                  = "aks-cluster.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

# Create networking module
module "networking" {
  source              = "./modules/networking"
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_name           = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  subnet_names        = ["aks-subnet", "app-subnet"]
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24"]
  tags                = var.tags
}

# Create AKS cluster
module "aks" {
  source                          = "./modules/aks"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  cluster_name                    = "${var.prefix}-aks"
  kubernetes_version              = var.kubernetes_version
  vnet_subnet_id                  = module.networking.subnet_ids["aks-subnet"]
  default_node_pool_count         = var.node_count
  default_node_pool_vm_size       = var.vm_size
  system_node_pool_count          = var.system_node_count
  system_node_pool_vm_size        = var.system_vm_size
  app_node_pool_count             = var.app_node_count
  app_node_pool_vm_size           = var.app_vm_size
  app_node_pool_min_count         = var.min_app_node_count
  app_node_pool_max_count         = var.max_app_node_count
  enable_auto_scaling             = true
  log_analytics_workspace_enabled = true
  tags                            = var.tags
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = module.aks.kube_config_host
  client_certificate     = base64decode(module.aks.kube_config_client_certificate)
  client_key             = base64decode(module.aks.kube_config_client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config_cluster_ca_certificate)
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config_host
    client_certificate     = base64decode(module.aks.kube_config_client_certificate)
    client_key             = base64decode(module.aks.kube_config_client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config_cluster_ca_certificate)
  }
}

# Create namespaces for applications
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

resource "kubernetes_namespace" "historical_network" {
  metadata {
    name = "historical-network"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

# Install Istio using Helm
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = var.istio_version
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  timeout = 900
  
  depends_on = [
    module.aks,
    kubernetes_namespace.istio_system
  ]
}

resource "helm_release" "istio_istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = var.istio_version
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  timeout = 900

  set {
    name  = "pilot.resources.requests.cpu"
    value = "500m"
  }
  set {
    name  = "pilot.resources.requests.memory"
    value = "2048Mi"
  }
  set {
    name  = "global.tracer.zipkin.address"
    value = "zipkin.istio-system:9411"
  }

  depends_on = [
    helm_release.istio_base
  ]
}

resource "helm_release" "istio_gateway" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.istio_version
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  timeout = 900

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "autoscaling.enabled"
    value = "true"
  }
  set {
    name  = "autoscaling.minReplicas"
    value = "1"
  }
  set {
    name  = "autoscaling.maxReplicas"
    value = "5"
  }

  depends_on = [
    helm_release.istio_istiod
  ]
}

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  timeout = 900

  values = [
    <<-EOF
    global:
      image:
        tag: "${var.argocd_version}"
    server:
      extraArgs:
        - --insecure
      service:
        type: ClusterIP
    controller:
      resources:
        limits:
          cpu: 500m
          memory: 512Mi
        requests:
          cpu: 250m
          memory: 256Mi
    repoServer:
      resources:
        limits:
          cpu: 300m
          memory: 256Mi
        requests:
          cpu: 100m
          memory: 128Mi
    applicationSet:
      resources:
        limits:
          cpu: 200m
          memory: 256Mi
        requests:
          cpu: 100m
          memory: 128Mi
    redis:
      resources:
        limits:
          cpu: 200m
          memory: 128Mi
        requests:
          cpu: 100m
          memory: 64Mi
    dex:
      resources:
        limits:
          cpu: 100m
          memory: 128Mi
        requests:
          cpu: 50m
          memory: 64Mi
    EOF
  ]

  depends_on = [
    kubernetes_namespace.argocd,
    helm_release.istio_gateway
  ]
}

# Create ArgoCD project for system components
resource "kubernetes_manifest" "argocd_project_system" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = "system"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      description = "System components"
      sourceRepos = ["*"]
      destinations = [{
        namespace = "*"
        server    = "https://kubernetes.default.svc"
      }]
      clusterResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]
    }
  }

  depends_on = [
    helm_release.argocd
  ]
}

# Get the External IP of the istio-ingressgateway
data "kubernetes_service" "istio_ingress" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = kubernetes_namespace.istio_system.metadata[0].name
  }

  depends_on = [
    helm_release.istio_gateway
  ]
}

locals {
  # Get the external IP of Istio ingress gateway or use a placeholder for plan/apply
  istio_ingress_ip = try(
    data.kubernetes_service.istio_ingress.status.0.load_balancer.0.ingress.0.ip,
    "PENDING_IP"
  )
  
  # Determine the base domain - either nip.io with the IP or the provided domain
  base_domain = var.use_nip_io ? "${local.istio_ingress_ip}.nip.io" : var.domain_name
  
  # Define all the domains we'll need
  domains = {
    argocd              = "argocd.${local.base_domain}"
    historical_network  = "historical-network.${local.base_domain}"
    kiali               = "kiali.${local.base_domain}"
    jaeger              = "jaeger.${local.base_domain}"
    prometheus          = "prometheus.${local.base_domain}"
    grafana             = "grafana.${local.base_domain}"
  }
}

# Create Istio Gateway for ArgoCD
resource "kubernetes_manifest" "argocd_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "argocd-gateway"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [{
        port = {
          number   = 80
          name     = "http"
          protocol = "HTTP"
        }
        hosts = [local.domains.argocd]
      }]
    }
  }

  depends_on = [
    helm_release.istio_gateway,
    helm_release.argocd
  ]
}

# Create VirtualService for ArgoCD
resource "kubernetes_manifest" "argocd_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "argocd-server"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      hosts    = [local.domains.argocd]
      gateways = ["argocd-gateway"]
      http = [{
        route = [{
          destination = {
            host = "argocd-server"
            port = {
              number = 80
            }
          }
        }]
      }]
    }
  }

  depends_on = [
    kubernetes_manifest.argocd_gateway
  ]
}

# Create Istio Gateway for Historical Network
resource "kubernetes_manifest" "historical_network_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "historical-network-gateway"
      namespace = kubernetes_namespace.historical_network.metadata[0].name
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [{
        port = {
          number   = 80
          name     = "http"
          protocol = "HTTP"
        }
        hosts = [local.domains.historical_network]
      }]
    }
  }

  depends_on = [
    helm_release.istio_gateway
  ]
}

# Create VirtualService for Historical Network
resource "kubernetes_manifest" "historical_network_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "historical-network"
      namespace = kubernetes_namespace.historical_network.metadata[0].name
    }
    spec = {
      hosts    = [local.domains.historical_network]
      gateways = ["historical-network-gateway"]
      http = [{
        match = [{
          uri = {
            prefix = "/"
          }
        }]
        route = [{
          destination = {
            host = "historical-network"
            port = {
              number = 80
            }
          }
        }]
      }]
    }
  }

  depends_on = [
    kubernetes_manifest.historical_network_gateway
  ]
}

# Create ArgoCD Application for Historical Network
resource "kubernetes_manifest" "argocd_application_historical_network" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "historical-network"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/jbrcoleman/historic-network"
        targetRevision = "HEAD"
        path           = "k8s"
        helm = {
          values = <<-EOT
            ingress:
              host: "${local.domains.historical_network}"
            wikipedia:
              scrapeInterval: 3600
              maxDepth: 2
              maxRelatedPerFigure: 10
              seedFigures:
                - "Albert Einstein"
                - "Marie Curie"
                - "Isaac Newton"
          EOT
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.historical_network.metadata[0].name
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=false"]
      }
    }
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_namespace.historical_network
  ]
}

# Output the domains for use in other modules or for user information
output "domains" {
  value = local.domains
  description = "All the domain names configured for services"
}

output "istio_ingress_ip" {
  value = local.istio_ingress_ip
  description = "External IP address of the Istio ingress gateway"
}

output "argocd_admin_password" {
  value = "To retrieve the password, run: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  description = "Command to get the ArgoCD admin password"
}

output "kubernetes_cluster_name" {
  value = module.aks.kubernetes_cluster_name
  description = "Name of the AKS cluster"
}

output "resource_group_name" {
  value = var.resource_group_name
  description = "Name of the resource group"
}