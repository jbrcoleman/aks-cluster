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
  default     = "1.31"
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
