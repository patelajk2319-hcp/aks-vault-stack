# =============================================================================
# Provider Configuration for JWT Authentication
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {

    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# -----------------------------------------------------------------------------
# Vault Provider
# Connects to Vault using environment variables:
# -----------------------------------------------------------------------------
provider "vault" {

}

# -----------------------------------------------------------------------------
# Kubernetes Provider
# Uses default kubeconfig discovery (~/.kube/config)
# Kubeconfig is configured by: az aks get-credentials --admin
# -----------------------------------------------------------------------------
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "aks-vault-cluster-admin"
}
