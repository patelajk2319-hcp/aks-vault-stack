# =============================================================================
# Vault Audit Device Configuration
# Enables file-based audit logging for all Vault API requests and responses
# IMPORTANT: Must run AFTER Vault is initialised and unsealed
# =============================================================================

# File-based audit device for persistent audit logging
resource "vault_audit" "file" {
  type = "file"
  path = "file"

  options = {
    file_path = "/vault/data/audit.log"
    mode      = "0640" # Owner read/write, group read-only, no world access
  }

  description = "File-based audit device for persistent audit logging"
}
