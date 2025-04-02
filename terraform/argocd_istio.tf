# Create the Application for Istio
resource "kubernetes_manifest" "argocd_application_istio" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "istio"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      project = kubernetes_manifest.argocd_project_system.manifest.metadata.name
      source = {
        repoURL        = "https://github.com/jbrcoleman/aks-infrastructure"
        targetRevision = "HEAD"
        path           = "kubernetes/istio"
        helm = {
          values = <<-EOT
            domains:
              kiali: "${local.domains.kiali}"
              jaeger: "${local.domains.jaeger}"
              prometheus: "${local.domains.prometheus}"
              grafana: "${local.domains.grafana}"
              historicalNetwork: "${local.domains.historical_network}"
          EOT
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.istio_system.metadata[0].name
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
    kubernetes_manifest.argocd_project_system,
    kubernetes_namespace.istio_system
  ]
}

# Update the historical network application to use the nip.io domain
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
    kubernetes_manifest.argocd_project_system,
    kubernetes_namespace.historical_network
  ]
}# Create the Application for Istio
resource "kubernetes_manifest" "argocd_application_istio" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "istio"
      namespace = kubernetes_namespace.argocd.metadata[0].name
    }
    spec = {
      project = kubernetes_manifest.argocd_project_system.manifest.metadata.name
      source = {
        repoURL        = "https://github.com/jbrcoleman/aks-infrastructure"
        targetRevision = "HEAD"
        path           = "kubernetes/istio"
        helm = {
          values = <<-EOT
            domains:
              kiali: "${local.domains.kiali}"
              jaeger: "${local.domains.jaeger}"
              prometheus: "${local.domains.prometheus}"
              grafana: "${local.domains.grafana}"
              historicalNetwork: "${local.domains.historical_network}"
          EOT
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.istio_system.metadata[0].name
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
    kubernetes_manifest.argocd_project_system,
    kubernetes_namespace.istio_system
  ]
}

# Update the historical network application to use the nip.io domain
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
    kubernetes_manifest.argocd_project_system,
    kubernetes_namespace.historical_network
  ]
}