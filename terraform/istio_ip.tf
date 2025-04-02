# This data source waits for the Istio ingress gateway service to be created
# and extracts its external IP address
resource "null_resource" "wait_for_istio_ingress" {
  depends_on = [
    kubernetes_manifest.argocd_application_istio
  ]
  
  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=available --timeout=300s deployment/istio-ingressgateway -n istio-system || true
      # The above command might fail if the deployment isn't ready yet, but we don't want Terraform to fail
    EOT
  }
}

data "kubernetes_service" "istio_ingress" {
  metadata {
    name      = "istio-ingressgateway"
    namespace = "istio-system"
  }
  
  depends_on = [
    null_resource.wait_for_istio_ingress
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

# Output the domains for use in other modules or for user information
output "domains" {
  value = local.domains
  description = "All the domain names configured for services"
}

output "istio_ingress_ip" {
  value = local.istio_ingress_ip
  description = "External IP address of the Istio ingress gateway"
}