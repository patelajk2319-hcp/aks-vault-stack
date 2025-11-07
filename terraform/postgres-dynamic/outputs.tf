# =============================================================================
# PostgreSQL Database Configuration Outputs
# Exports values for use by workload modules
# =============================================================================

output "database_mount_path" {
  description = "Path where database secrets engine is mounted"
  value       = vault_mount.database.path
}

output "database_role_name" {
  description = "Name of the PostgreSQL database role"
  value       = vault_database_secret_backend_role.postgres.name
}

output "credential_ttl_seconds" {
  description = "TTL for database credentials in seconds"
  value       = local.credential_ttl_seconds
}
