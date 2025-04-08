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
    service_cidr       = "172.16.0.0/16"
    dns_service_ip     = "172.16.0.10"
  }

  azure_active_directory_role_based_access_control {
  managed = true 
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