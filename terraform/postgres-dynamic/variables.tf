# =============================================================================
# Vault Configuration Variables
# Parameters for setting up Vault database secrets engine
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace where workload is deployed"
  type        = string
  default     = "vault"
}

variable "postgres_connection_url" {
  description = "PostgreSQL connection URL with admin credentials"
  type        = string
  sensitive   = true
}
