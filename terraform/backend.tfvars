# # Azure Subscription Details
# subscription_id = "your-subscription-id"
# tenant_id       = "your-tenant-id"

# Resource Configuration
prefix             = "historicalnet"
resource_group_name = "historical-network-rg"
location           = "southuk"

# AKS Configuration
kubernetes_version = "1.28.3"
node_count         = 3
vm_size            = "Standard_D2s_v3"
system_node_count  = 2  
system_vm_size     = "Standard_D2s_v3"
app_node_count     = 2
app_vm_size        = "Standard_D4s_v3"

# Helm Chart Versions
argocd_version     = "5.51.4"
istio_version      = "1.20.2"

# DNS Configuration
use_nip_io         = false
