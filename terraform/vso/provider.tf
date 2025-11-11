terraform {
  required_version = ">= 1.5.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# -----------------------------------------------------------------------------
# Kubernetes Provider
# Uses default kubeconfig discovery (~/.kube/config)
# Automatically uses the current kubectl context
# Context is configured by: az aks get-credentials --admin
# -----------------------------------------------------------------------------
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# -----------------------------------------------------------------------------
# Helm Provider
# Uses default kubeconfig discovery (~/.kube/config)
# Automatically discovers and uses the same kubeconfig as Kubernetes provider
# -----------------------------------------------------------------------------
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
