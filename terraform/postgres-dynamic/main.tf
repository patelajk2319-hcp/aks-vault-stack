# =============================================================================
# Vault Configuration for Postgress Dynamic Credentials. 
# This configures Vault so Vault can manage dynamic credentials on Postgress database
# =============================================================================

# -----------------------------------------------------------------------------
# JWT Auth Backend - Kubernetes workload authentication
# -----------------------------------------------------------------------------
resource "vault_jwt_auth_backend" "jwt" {
  path               = "jwt"
  type               = "jwt"
  description        = "JWT authentication for Kubernetes workloads"
  oidc_discovery_url = var.oidc_issuer_url
  bound_issuer       = var.oidc_issuer_url
}

# -----------------------------------------------------------------------------
# JWT Role - VSO service account authentication
# -----------------------------------------------------------------------------
resource "vault_jwt_auth_backend_role" "vso" {
  backend        = vault_jwt_auth_backend.jwt.path
  role_name      = "vso"
  token_policies = [vault_policy.vso.name]

  bound_audiences = ["https://kubernetes.default.svc.cluster.local"]
  bound_subject   = "system:serviceaccount:${var.namespace}:vault-secrets-operator-controller-manager"
  
  user_claim      = "sub"
  role_type       = "jwt"
  token_ttl       = 3600
  token_max_ttl   = 7200
}

# -----------------------------------------------------------------------------
# Database Secrets Engine
# -----------------------------------------------------------------------------
resource "vault_mount" "database" {
  path        = "database"
  type        = "database"
  description = "PostgreSQL dynamic credentials engine"
}

# -----------------------------------------------------------------------------
# PostgreSQL Connection Configuration
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
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# VSO Access Policy
# -----------------------------------------------------------------------------
resource "vault_policy" "vso" {
  name   = "vso-policy"
  policy = data.vault_policy_document.vso.hcl
}