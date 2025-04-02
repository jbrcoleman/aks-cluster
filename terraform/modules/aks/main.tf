# modules/aks/main.tf

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.log_analytics_workspace_enabled ? 1 : 0
  name                = "${var.cluster_name}-workspace"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  
  default_node_pool {
    name                = "default"
    node_count          = var.default_node_pool_count
    vm_size             = var.default_node_pool_vm_size
    vnet_subnet_id      = var.vnet_subnet_id
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.default_node_pool_min_count : null
    max_count           = var.enable_auto_scaling ? var.default_node_pool_max_count : null
    os_disk_size_gb     = 50
    type                = "VirtualMachineScaleSets"
    node_labels = {
      "role" = "general"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_enabled ? azurerm_log_analytics_workspace.aks[0].id : null
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    load_balancer_sku  = "standard"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "system" {
  name                  = "system"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.system_node_pool_vm_size
  node_count            = var.system_node_pool_count
  vnet_subnet_id        = var.vnet_subnet_id
  mode                  = "System"
  
  node_labels = {
    "role" = "system"
  }
  
  node_taints = [
    "CriticalAddonsOnly=true:NoSchedule"
  ]

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "app" {
  name                  = "app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.app_node_pool_vm_size
  node_count            = var.app_node_pool_count
  vnet_subnet_id        = var.vnet_subnet_id
  enable_auto_scaling   = true
  min_count             = var.app_node_pool_min_count
  max_count             = var.app_node_pool_max_count
  
  node_labels = {
    "role" = "app"
  }

  tags = var.tags
}

# modules/aks/variables.tf

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.3"
}

variable "vnet_subnet_id" {
  description = "ID of the subnet where the AKS cluster will be deployed"
  type        = string
}

variable "default_node_pool_count" {
  description = "Number of nodes in default node pool"
  type        = number
  default     = 2
}

variable "default_node_pool_vm_size" {
  description = "VM size for default node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "default_node_pool_min_count" {
  description = "Minimum node count for default node pool autoscaling"
  type        = number
  default     = 1
}

variable "default_node_pool_max_count" {
  description = "Maximum node count for default node pool autoscaling"
  type        = number
  default     = 5
}

variable "system_node_pool_count" {
  description = "Number of nodes in system node pool"
  type        = number
  default     = 2
}

variable "system_node_pool_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "app_node_pool_count" {
  description = "Number of nodes in app node pool"
  type        = number
  default     = 2
}

variable "app_node_pool_vm_size" {
  description = "VM size for app node pool"
  type        = string
  default     = "Standard_DS4_v2"
}

variable "app_node_pool_min_count" {
  description = "Minimum node count for app node pool autoscaling"
  type        = number
  default     = 1
}

variable "app_node_pool_max_count" {
  description = "Maximum node count for app node pool autoscaling"
  type        = number
  default     = 5
}

variable "enable_auto_scaling" {
  description = "Enable node pool autoscaling"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_enabled" {
  description = "Enable Log Analytics workspace"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "AD Groups that have admin access to the cluster"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# modules/aks/outputs.tf

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