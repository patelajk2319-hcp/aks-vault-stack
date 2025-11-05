# =============================================================================
# Vault Configuration for Dynamic Credentials
# Sets up JWT auth and PostgreSQL secrets engine
# =============================================================================

# -----------------------------------------------------------------------------
# JWT Auth Backend
# Enables Kubernetes pods to authenticate to Vault using service account JWT tokens
# -----------------------------------------------------------------------------
resource "vault_jwt_auth_backend" "jwt" {
  path               = "jwt"
  type               = "jwt"
  oidc_discovery_url = var.oidc_issuer_url
  bound_issuer       = var.oidc_issuer_url
}

# -----------------------------------------------------------------------------
# JWT Auth Role for VSO
# Allows the Vault Secrets Operator service account to authenticate and access database secrets using JWT tokens
# -----------------------------------------------------------------------------
resource "vault_jwt_auth_backend_role" "vso" {
  backend        = vault_jwt_auth_backend.jwt.path
  role_name      = "vso"
  token_policies = [vault_policy.vso.name]

  bound_audiences   = ["https://kubernetes.default.svc.cluster.local"]
  bound_subject     = "system:serviceaccount:${var.namespace}:vault-secrets-operator-controller-manager"
  user_claim        = "sub"
  role_type         = "jwt"
  token_ttl         = 3600
  token_max_ttl     = 7200
}

# -----------------------------------------------------------------------------
# Database Secrets Engine
# -----------------------------------------------------------------------------
resource "vault_mount" "database" {
  path = "database"
  type = "database"
}

# -----------------------------------------------------------------------------
# Configures Vault to connect to PostgreSQL server
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# PostgreSQL Database Role
# Defines the SQL statements to create and revoke database users
# -----------------------------------------------------------------------------
resource "vault_database_secret_backend_role" "postgres" {
  backend             = vault_mount.database.path
  name                = "postgres-role"
  db_name             = vault_database_secret_backend_connection.postgres.name
  default_ttl         = 300  # 5 minutes - credentials expire quickly
  max_ttl             = 600  # 10 minutes - maximum lifetime
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
    "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";"
  ]
  revocation_statements = [
    "DROP ROLE IF EXISTS \"{{name}}\";"
  ]
}
