# =============================================================================
# Vault Deployment Variables
# Configuration parameters for deploying Vault and VSO to AKS
# =============================================================================

# -----------------------------------------------------------------------------
# Namespace Configuration
# Note: AKS connection uses kubeconfig (~/.kube/config)
# Configured by deployment script via: az aks get-credentials
# -----------------------------------------------------------------------------

variable "namespace" {
  description = "Kubernetes namespace for Vault and VSO deployment"
  type        = string
  default     = "vault"
}

# -----------------------------------------------------------------------------
# Vault Configuration
# -----------------------------------------------------------------------------

variable "vault_chart_version" {
  description = "Version of the Vault Helm chart to deploy"
  type        = string
  default     = "0.31.0"
}

# Note: Vault Enterprise licence is read from licenses/vault-enterprise/license.lic
# Note: All Vault configuration (replica count, storage, image) is in the values YAML file

# -----------------------------------------------------------------------------
# Resource Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
