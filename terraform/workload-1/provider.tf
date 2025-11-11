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

# Vault Provider
provider "vault" {

}

# Kubernetes Provider
# Automatically uses the current kubectl context
# Context is configured by: az aks get-credentials --admin
provider "kubernetes" {
  config_path = "~/.kube/config"
}
