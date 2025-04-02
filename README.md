# AKS Cluster Deployment Guide with Terraform

This guide provides instructions for deploying an AKS cluster with ArgoCD and Istio using Terraform.

## Project Structure

```
aks-cluster/
├── terraform/
│   ├── modules/
│   │   ├── aks/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── networking/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── terraform.tfvars
├── k8s/
│   ├── templates/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── Chart.yaml
│   └── values.yaml
└── README.md
```

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and configured
- [Terraform](https://www.terraform.io/downloads.html) (version 1.0.0+) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- Azure subscription with appropriate permissions
- GitHub account with access to the repository

## Deployment Steps

### 1. Clone the Repository

```bash
git clone https://github.com/jbrcoleman/aks-cluster.git
cd aks-cluster
```

### 2. Configure Azure Authentication

There are several ways to authenticate with Azure. Choose one of the following methods:

#### Option A: Using Azure CLI

```bash
az login
az account set --subscription "your-subscription-id"
```

#### Option B: Using Service Principal

Create a service principal with contributor access to your subscription:

```bash
az ad sp create-for-rbac --name "aks-terraform-sp" --role="Contributor" --scopes="/subscriptions/your-subscription-id"
```

Note the `appId`, `password`, and `tenant` values for use in the next step.

### 3. Configure Terraform Variables

Create a `terraform.tfvars` file in the terraform directory:

```hcl
# Azure Subscription Details
subscription_id = "your-subscription-id"
tenant_id       = "your-tenant-id"
client_id       = "service-principal-app-id"      # Only needed for service principal authentication
client_secret   = "service-principal-password"    # Only needed for service principal authentication

# Resource Configuration
prefix             = "historicalnet"
resource_group_name = "historical-network-rg"
location           = "eastus"

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
use_nip_io         = true  # Set to false if using a custom domain
domain_name        = "example.com"  # Only used if use_nip_io = false
```

### 4. Configure Terraform Backend (Optional but Recommended)

For production environments, it's recommended to use remote state storage. Create a backend configuration file named `backend.tfvars`:

```hcl
resource_group_name  = "terraform-state-rg"
storage_account_name = "terraformstatesa"
container_name       = "terraform-state"
key                  = "aks-cluster.terraform.tfstate"
```

First, create the Azure storage account:

```bash
az group create --name terraform-state-rg --location eastus
az storage account create --name terraformstatesa --resource-group terraform-state-rg --sku Standard_LRS
az storage container create --name terraform-state --account-name terraformstatesa
```

Get the storage account key:

```bash
az storage account keys list --account-name terraformstatesa --resource-group terraform-state-rg --query "[0].value" -o tsv
```

Set the storage account key as an environment variable:

```bash
export ARM_ACCESS_KEY=<storage-account-key>
```

### 5. Initialize and Apply Terraform

```bash
cd terraform

# Initialize Terraform with backend configuration
terraform init -backend-config=backend.tfvars

# Validate the configuration
terraform validate

# Plan the deployment
terraform plan -out=tfplan

# Apply the configuration
terraform apply tfplan
```

The deployment will take approximately 15-20 minutes to complete.

### 6. Access Your Cluster

After the deployment completes, Terraform will output information about how to access your cluster:

```
Outputs:

argocd_admin_password = "To retrieve the password, run: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
domains = {
  "argocd" = "argocd.51.138.42.90.nip.io"
  "grafana" = "grafana.51.138.42.90.nip.io"
  "historical_network" = "historical-network.51.138.42.90.nip.io"
  "jaeger" = "jaeger.51.138.42.90.nip.io"
  "kiali" = "kiali.51.138.42.90.nip.io"
  "prometheus" = "prometheus.51.138.42.90.nip.io"
}
istio_ingress_ip = "51.138.42.90"
kubernetes_cluster_name = "historicalnet-aks"
resource_group_name = "historical-network-rg"
```

### 7. Connect to the AKS Cluster

Configure kubectl to use the AKS cluster:

```bash
az aks get-credentials --resource-group historical-network-rg --name historicalnet-aks
```

Verify the connection:

```bash
kubectl get nodes
```

### 8. Access ArgoCD

1. Get the ArgoCD admin password:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

2. Access the ArgoCD UI by navigating to `http://argocd.51.138.42.90.nip.io` in your browser (replace the IP with your actual Istio ingress IP)

3. Log in with:
   - Username: `admin`
   - Password: (the password obtained from the previous step)

### 9. Configure the Historical Network Application in ArgoCD

ArgoCD has been configured to track your `historic-network` repository, but you may need to sync it manually the first time:

1. In the ArgoCD UI, click on the "historical-network" application
2. Click "Sync" to deploy the application
3. Verify all resources are healthy

### 10. Access the Historical Network Application

Navigate to `http://historical-network.51.138.42.90.nip.io` in your browser (replace the IP with your actual Istio ingress IP).

## Adding Wikipedia Scraping and NLP Functionality

To implement the Wikipedia scraping and NLP functionality for analyzing relationships between historical figures:

1. Fork the repository at https://github.com/jbrcoleman/historic-network
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/historic-network.git
   cd historic-network
   ```

3. Create a Python script for Wikipedia scraping and NLP (example structure):
   ```
   src/
   ├── wikipedia/
   │   ├── __init__.py
   │   ├── scraper.py
   │   └── network_builder.py
   ├── nlp/
   │   ├── __init__.py
   │   ├── relationship_analyzer.py
   │   └── entity_extractor.py
   └── main.py
   ```

4. Update the Dockerfile to include the new dependencies:
   ```dockerfile
   FROM python:3.9-slim

   WORKDIR /app

   # Install dependencies
   COPY requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt

   # Copy application code
   COPY src/ ./src/

   # Run the application
   CMD ["python", "src/main.py"]
   ```

5. Update requirements.txt:
   ```
   requests==2.31.0
   beautifulsoup4==4.12.2
   spacy==3.7.2
   networkx==3.1
   pandas==2.0.3
   flask==2.3.3
   gunicorn==21.2.0
   python-dotenv==1.0.0
   ```

6. Install spaCy language model in the Dockerfile:
   ```dockerfile
   # Add after pip install
   RUN python -m spacy download en_core_web_lg
   ```

7. Push changes to your repository:
   ```bash
   git add .
   git commit -m "Add Wikipedia scraping and NLP functionality"
   git push
   ```

8. Update the ArgoCD application to point to your repository:
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: historical-network
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/YOUR-USERNAME/historic-network
       targetRevision: HEAD
       path: k8s
     destination:
       server: https://kubernetes.default.svc
       namespace: historical-network
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
   EOF
   ```

## Monitoring and Observability

Istio comes with several monitoring tools:

1. **Kiali** (Service Mesh Visualization): http://kiali.51.138.42.90.nip.io
2. **Jaeger** (Distributed Tracing): http://jaeger.51.138.42.90.nip.io
3. **Prometheus** (Metrics): http://prometheus.51.138.42.90.nip.io
4. **Grafana** (Dashboards): http://grafana.51.138.42.90.nip.io

## Troubleshooting

### Common Issues and Solutions

1. **Pods stuck in Pending state**:
   ```bash
   kubectl get pods --all-namespaces | grep Pending
   kubectl describe pod [pod-name] -n [namespace]
   ```
   Possible solution: Check if there are enough resources in the cluster or if there are taints/tolerations issues.

2. **ArgoCD cannot connect to GitHub**:
   Check if the repository is public or if you've configured the proper SSH keys or access tokens.

3. **Istio Gateway not working**:
   ```bash
   kubectl get gateway -A
   kubectl get virtualservice -A
   kubectl logs -n istio-system -l app=istio-ingressgateway
   ```

4. **External IP not assigned to Istio Ingress Gateway**:
   ```bash
   kubectl get svc -n istio-system istio-ingressgateway
   ```
   Ensure your Azure Network Security Group allows traffic on ports 80 and 443.

## Clean Up Resources

When you're done with the cluster, clean up all resources to avoid unnecessary charges:

```bash
cd terraform
terraform destroy
```

## Next Steps

- Set up CI/CD pipelines for automating the build and deployment of the Historical Network application
- Implement HTTPS with Let's Encrypt
- Add user authentication
- Expand the NLP capabilities to identify more complex relationships
- Create custom Grafana dashboards for monitoring the application performance