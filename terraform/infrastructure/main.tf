# Create networking module
module "networking" {
  source              = "../modules/networking"
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
  source                          = "../modules/aks"
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
  enable_auto_scaling             = false
  log_analytics_workspace_enabled = true
  tags                            = var.tags
}