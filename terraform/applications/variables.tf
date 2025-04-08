# 2-applications/variables.tf
variable "argocd_version" {
  description = "Version of ArgoCD Helm chart"
  type        = string
  default     = "5.51.4"
}

variable "istio_version" {
  description = "Version of Istio Helm charts"
  type        = string
  default     = "1.20.2"
}

variable "use_nip_io" {
  description = "Whether to use nip.io domains"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Custom domain name if not using nip.io"
  type        = string
  default     = "example.com"
}