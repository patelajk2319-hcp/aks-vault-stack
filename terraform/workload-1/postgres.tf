# PostgreSQL Database Configuration
resource "vault_mount" "database" {
  path        = "database"
  type        = "database"
  description = "PostgreSQL dynamic credentials engine"
}

# PostgreSQL Connection
resource "vault_database_secret_backend_connection" "postgres" {
  backend       = vault_mount.database.path
  name          = "postgres"
  allowed_roles = ["postgres-role"]

  postgresql {
    connection_url       = var.postgres_connection_url
    max_open_connections = 5
    max_idle_connections = 0
  }

  verify_connection = true
}

# PostgreSQL Role
resource "vault_database_secret_backend_role" "postgres" {
  backend     = vault_mount.database.path
  name        = "postgres-role"
  db_name     = vault_database_secret_backend_connection.postgres.name
  default_ttl = local.credential_ttl_seconds
  max_ttl     = local.credential_max_ttl_seconds
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
    "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";"
  ]
  revocation_statements = [
    "DROP ROLE IF EXISTS \"{{name}}\";"
  ]
}
