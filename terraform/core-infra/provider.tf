

terraform {

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.6"
    }
  }
  # Require Terraform version 1.5 or higher
  required_version = ">= 1.5"
}


provider "azurerm" {
  # features block is required (even if empty) for azurerm provider v2.0+
  features {
    resource_group {
      # For demo environments allow force delete of resource groups with nested resources
      # This prevents errors when AKS creates resources (like ContainerInsights) that Terraform doesn't track
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {
  # Azure AD tenant ID (must match the Azure subscription's tenant)
  tenant_id = var.tenant_id
}
