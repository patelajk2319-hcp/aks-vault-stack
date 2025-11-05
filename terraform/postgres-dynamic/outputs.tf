# =============================================================================
# Vault Configuration Outputs
# Information about configured auth and secrets engines
# =============================================================================

output "jwt_auth_path" {
  description = "Path where JWT auth is mounted"
  value       = vault_jwt_auth_backend.jwt.path
}

output "database_mount_path" {
  description = "Path where database secrets engine is mounted"
  value       = vault_mount.database.path
}

output "database_role_name" {
  description = "Name of the PostgreSQL database role"
  value       = vault_database_secret_backend_role.postgres.name
}

output "vso_role_name" {
  description = "Name of the JWT auth role for VSO"
  value       = vault_jwt_auth_backend_role.vso.role_name
}

output "dynamic_creds_path" {
  description = "Path to read dynamic PostgreSQL credentials"
  value       = "database/creds/${vault_database_secret_backend_role.postgres.name}"
}
