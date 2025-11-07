# =============================================================================
# JWT Authentication and Workload Variables
# Parameters for setting up JWT authentication and VSO configuration
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace where the workload is deployed"
  type        = string
  default     = "vault"
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL from AKS cluster for JWT authentication"
  type        = string
}

variable "database_mount_path" {
  description = "Path where database secrets engine is mounted in Vault"
  type        = string
  default     = "database"
}

variable "database_role_name" {
  description = "Name of the database role to request credentials from"
  type        = string
  default     = "postgres-role"
}

variable "credential_ttl_seconds" {
  description = "TTL for database credentials in seconds (from postgres-dynamic module)"
  type        = number
  default     = 300
}
