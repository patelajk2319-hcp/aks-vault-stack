# =============================================================================
# Local Values - VSO Refresh Timing
# Calculates when VSO should refresh credentials based on Vault TTL
# =============================================================================

locals {
  # VSO refreshes at 80% of TTL for smooth rotation with 60s overlap
  vso_refresh_after_seconds = var.credential_ttl_seconds * 0.8
  vso_refresh_after         = "${local.vso_refresh_after_seconds}s"
}
