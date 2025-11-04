

terraform {

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Use any 3.x version
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0" # Use any 2.x version
    }
  }
  # Require Terraform version 1.0 or higher
  required_version = ">= 1.0"
}


provider "azurerm" {
  # features block is required (even if empty) for azurerm provider v2.0+
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {
  # Azure AD tenant ID (must match the Azure subscription's tenant)
  tenant_id = var.tenant_id
}
