# =============================================================================
# Provider Configuration for Vault Audit Devices
# Configures Vault provider to enable audit devices
# IMPORTANT: Only official HashiCorp providers are used
# NEVER use community providers - always use official sources
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Official Vault provider from HashiCorp
    # Source: https://registry.terraform.io/providers/hashicorp/vault
    # Published by: HashiCorp (official Vault provider)
    # Used to configure Vault audit devices
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Vault Provider
# Connects to Vault via port-forward at localhost:8200
# Requires VAULT_ADDR and VAULT_TOKEN environment variables
# Must be configured AFTER Vault is initialised and unsealed
# -----------------------------------------------------------------------------
provider "vault" {

}
