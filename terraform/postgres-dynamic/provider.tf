# =============================================================================
# Provider Configuration for Vault Configuration
# Configures Vault provider to set up auth and secrets engines
# IMPORTANT: Only official HashiCorp providers are used
# NEVER use community providers - always use official sources
# Vault must be initialised and unsealed before running this configuration
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Official Vault provider from HashiCorp
    # Source: https://registry.terraform.io/providers/hashicorp/vault
    # Published by: HashiCorp (official Vault provider)
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Vault Provider
# Connects to Vault using environment variables:
# - VAULT_ADDR: Vault server address (from .env)
# - VAULT_TOKEN: Root token (from .env)
# -----------------------------------------------------------------------------
provider "vault" {
  # Configuration via environment variables:
  # export VAULT_ADDR=http://localhost:8200
  # export VAULT_TOKEN=<root_token>
  #
  # These are set automatically in .env by the vault init script
}
