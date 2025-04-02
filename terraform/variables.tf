variable "prefix" {
  description = "Prefix for resource names"
  default     = "historicalnet"
}

variable "location" {
  description = "Azure region where resources will be created"
  default     = "eastus"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  default     = "dev"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  default     = "1.28.0"
}

variable "node_count" {
  description = "Number of nodes for the default node pool"
  default     = 3
}

variable "min_node_count" {
  description = "Minimum number of nodes for the default node pool autoscaling"
  default     = 2
}

variable "max_node_count" {
  description = "Maximum number of nodes for the default node pool autoscaling"
  default     = 5
}

variable "vm_size" {
  description = "VM size for the default node pool"
  default     = "Standard_D2s_v3"
}

variable "system_node_count" {
  description = "Number of nodes for the system node pool"
  default     = 2
}

variable "system_vm_size" {
  description = "VM size for the system node pool"
  default     = "Standard_D2s_v3"
}

variable "app_node_count" {
  description = "Number of nodes for the application node pool"
  default     = 2
}

variable "min_app_node_count" {
  description = "Minimum number of nodes for the application node pool autoscaling"
  default     = 1
}

variable "max_app_node_count" {
  description = "Maximum number of nodes for the application node pool autoscaling"
  default     = 5
}

variable "app_vm_size" {
  description = "VM size for the application node pool"
  default     = "Standard_D4s_v3"
}

variable "subscription_id" {
  description = "Azure subscription ID"
}

variable "tenant_id" {
  description = "Azure tenant ID"
}

variable "client_id" {
  description = "Azure client ID"
  default     = ""
}

variable "client_secret" {
  description = "Azure client secret"
  default     = ""
  sensitive   = true
}

variable "argocd_chart_version" {
  description = "Version of the ArgoCD Helm chart"
  default     = "6.7.0"
}

variable "domain_name" {
  description = "Base domain name for the applications"
  default     = "example.com"
}

variable "use_nip_io" {
  description = "Whether to use nip.io for automatic DNS resolution"
  type        = bool
  default     = true
