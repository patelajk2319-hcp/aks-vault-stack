# =============================================================================
# Vault Audit Device Configuration
# IMPORTANT: Must run AFTER Vault is initialised and unsealed
# =============================================================================

# Main audit device for general operations (excludes database credentials)
resource "vault_audit" "file" {
  type = "file"
  path = "file"

  options = {
    file_path = "/vault/data/audit.log"
    mode      = "0640" # Owner read/write, group read-only, no world access
    # Exclude database credential operations (inverse of database filter)
    filter = "not ((operation == \"read\" and path matches \"database/creds/.+\") or (operation == \"update\" and path == \"sys/leases/renew\"))"
  }

  description = "File-based audit device for general operations (excludes database credential operations)"
}

# Dedicated audit device for database credential operations
# Captures: database/creds/* reads and sys/leases/renew operations
resource "vault_audit" "database" {
  type = "file"
  path = "file_database"

  options = {
    file_path = "/vault/data/audit_database.log"
    mode      = "0640"
    # Filter for database credential generation and lease renewal operations
    # Note: sys/leases/renew captures ALL lease renewals, not only database leases
    filter = "(operation == \"read\" and path matches \"database/creds/.+\") or (operation == \"update\" and path == \"sys/leases/renew\")"
  }

  description = "File-based audit device for database credential operations"
}
