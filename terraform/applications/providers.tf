# 2-applications/providers.tf

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "terraform-state"
    storage_account_name = "terraformstatesa21312"
    container_name       = "terraform-state"
    key                  = "historical-network-apps.terraform.tfstate"
  }
}

# Azure provider for accessing Azure resources
provider "azurerm" {
  features {}
}

# Use remote state to get AKS cluster info
data "terraform_remote_state" "infrastructure" {
  backend = "azurerm"
  config = {
    resource_group_name  = "terraform-state"
    storage_account_name = "terraformstatesa21312"
    container_name       = "terraform-state"
    key                  = "aks-cluster.terraform.tfstate"
  }
}

# Provider to get AKS credentials directly to avoid depending on local kubectl setup
data "azurerm_kubernetes_cluster" "aks" {
  name                =  "historicalnet-aks" //data.terraform_remote_state.infrastructure.outputs.kubernetes_cluster_name
  resource_group_name = "historical-network-rg"
}

# Configure Kubernetes provider using AKS credentials
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_config.0.host
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
  }
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks.kube_config.0.host
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
    }
  }
}