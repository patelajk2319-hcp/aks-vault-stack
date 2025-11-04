# =============================================================================
# Provider Configuration for Vault Deployment
# Configures Helm and Kubernetes providers to deploy Vault to AKS
# IMPORTANT: Only official HashiCorp providers are used
# NEVER use community providers - always use official sources
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    # Official Helm provider from HashiCorp
    # Source: https://registry.terraform.io/providers/hashicorp/helm
    # Published by: HashiCorp (official Kubernetes Helm provider)
    # Used to deploy official Vault Helm chart from https://helm.releases.hashicorp.com
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    # Official Kubernetes provider from HashiCorp
    # Source: https://registry.terraform.io/providers/hashicorp/kubernetes
    # Published by: HashiCorp (official Kubernetes provider)
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
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

# -----------------------------------------------------------------------------
# Helm Provider
# Uses default kubeconfig discovery (~/.kube/config)
# Automatically discovers and uses the same kubeconfig as Kubernetes provider
# -----------------------------------------------------------------------------
provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "aks-vault-cluster-admin"
  }
}
