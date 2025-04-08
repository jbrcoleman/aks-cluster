output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}

output "kubernetes_cluster_name" {
  value = module.aks.kubernetes_cluster_name
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "kubernetes_cluster_host" {
  value     = module.aks.kube_config_host
  sensitive = true
}

output "client_certificate" {
  value     = module.aks.kube_config_client_certificate
  sensitive = true
}

output "client_key" {
  value     = module.aks.kube_config_client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.aks.kube_config_cluster_ca_certificate
  sensitive = true
}