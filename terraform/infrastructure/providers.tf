terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "terraform-state"
    storage_account_name = "terraformstatesa21312"
    container_name       = "terraform-state"
    key                  = "aks-cluster.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}