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