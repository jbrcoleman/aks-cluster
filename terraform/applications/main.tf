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
    EOF
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}