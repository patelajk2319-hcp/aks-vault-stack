# Local Values

locals {
  database_mount_path = vault_mount.database.path
  database_role_name  = vault_database_secret_backend_role.postgres.name

  credential_ttl_seconds     = 300
  credential_max_ttl_seconds = 600

  # VSO refreshes at 80% of TTL for zero-downtime rotation
  vso_refresh_after_seconds = local.credential_ttl_seconds * 0.8
  vso_refresh_after         = "${local.vso_refresh_after_seconds}s"
}
