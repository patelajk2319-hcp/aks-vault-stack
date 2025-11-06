# =============================================================================
# VSO Deployment Variables
# Configuration parameters for deploying Vault Secrets Operator to AKS
# =============================================================================

# -----------------------------------------------------------------------------
# Namespace Configuration
# Note: AKS connection uses kubeconfig (~/.kube/config)
# Configured by deployment script via: az aks get-credentials
# -----------------------------------------------------------------------------

variable "namespace" {
  description = "Kubernetes namespace where Vault is deployed"
  type        = string
  default     = "vault"
}

# -----------------------------------------------------------------------------
# VSO Configuration
# -----------------------------------------------------------------------------

variable "vso_chart_version" {
  description = "Version of the Vault Secrets Operator Helm chart"
  type        = string
  default     = "0.10.0"
}

variable "vault_service_name" {
  description = "Name of the Vault service to connect to"
  type        = string
  default     = "vault"
}

