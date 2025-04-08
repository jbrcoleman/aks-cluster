variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "historicalnet"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "uksouth"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "historical-network-rg"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "Historical Network"
    ManagedBy   = "Terraform"
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.31"
}

variable "node_count" {
  description = "Number of nodes for the default node pool"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum number of nodes for the default node pool autoscaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes for the default node pool autoscaling"
  type        = number
  default     = 5
}

variable "vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "system_node_count" {
  description = "Number of nodes for the system node pool"
  type        = number
  default     = 1
}

variable "system_vm_size" {
  description = "VM size for the system node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "app_node_count" {
  description = "Number of nodes for the application node pool"
  type        = number
  default     = 1
}

variable "min_app_node_count" {
  description = "Minimum number of nodes for the application node pool autoscaling"
  type        = number
  default     = 1
}

variable "max_app_node_count" {
  description = "Maximum number of nodes for the application node pool autoscaling"
  type        = number
  default     = 5
}

variable "app_vm_size" {
  description = "VM size for the application node pool"
  type        = string
  default     = "Standard_D4s_v3"
}
/*
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "client_id" {
  description = "Azure client ID (service principal)"
  type        = string
  default     = ""
}

variable "client_secret" {
  description = "Azure client secret (service principal)"
  type        = string
  default     = ""
  sensitive   = true
}
*/