# =============================================================================
# Vault Policy Documents
# Defines policies using vault_policy_document data sources
# IMPORTANT: Always use policy documents, never use heredoc for policies
# =============================================================================

# -----------------------------------------------------------------------------
# wrkld1 Policy Document
# Grants workload 1 permission to read database credentials
# -----------------------------------------------------------------------------
data "vault_policy_document" "wrkld1" {
  rule {
    path         = "database/creds/*"
    capabilities = ["read"]
    description  = "Allow reading dynamic database credentials"
  }

  rule {
    path         = "database/creds/*"
    capabilities = ["list"]
    description  = "Allow listing database credential paths"
  }

  rule {
    path         = "database/roles"
    capabilities = ["list"]
    description  = "Allow listing database roles"
  }
}

# -----------------------------------------------------------------------------
# wrkld1 Policy
# -----------------------------------------------------------------------------
resource "vault_policy" "wrkld1" {
  name   = "wrkld1-policy"
  policy = data.vault_policy_document.wrkld1.hcl
}
