# =============================================================================
# Vault Policy Documents
# Defines policies using vault_policy_document data sources
# IMPORTANT: Always use policy documents, never use heredoc for policies
# =============================================================================

# -----------------------------------------------------------------------------
# VSO Policy Document
# Grants VSO permission to read database credentials and list roles
# -----------------------------------------------------------------------------
data "vault_policy_document" "vso" {
  rule {
    path         = "${vault_mount.database.path}/creds/${vault_database_secret_backend_role.postgres.name}"
    capabilities = ["read"]
    description  = "Allow reading dynamic PostgreSQL credentials"
  }

  rule {
    path         = "${vault_mount.database.path}/creds/*"
    capabilities = ["list"]
    description  = "Allow listing database credential paths"
  }

  rule {
    path         = "${vault_mount.database.path}/roles"
    capabilities = ["list"]
    description  = "Allow listing database roles"
  }
}

# -----------------------------------------------------------------------------
# VSO Policy Resource
# Creates the policy from the document
# -----------------------------------------------------------------------------
resource "vault_policy" "vso" {
  name   = "vso-policy"
  policy = data.vault_policy_document.vso.hcl
}
