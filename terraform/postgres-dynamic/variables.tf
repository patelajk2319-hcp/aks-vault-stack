# =============================================================================
# Vault Configuration Variables
# Parameters for setting up Vault JWT auth and secrets engines
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace where VSO is deployed"
  type        = string
  default     = "vault"
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL from AKS cluster for JWT authentication"
  type        = string
}

variable "postgres_connection_url" {
  description = "PostgreSQL connection URL with admin credentials"
  type        = string
  sensitive   = true
}
