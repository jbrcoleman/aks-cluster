
output "kubernetes_cluster_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "kubernetes_cluster_fqdn" {
  value = azurerm_kubernetes_cluster.aks.fqdn
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "kube_config_host" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.host
}

output "kube_config_client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config_client_key" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_key
  sensitive = true
}

output "kube_config_cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate
  sensitive = true
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "system_assigned_identity" {
  value = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}