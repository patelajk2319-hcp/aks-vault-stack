# =============================================================================
# Local Values - Credential TTL Configuration
# =============================================================================

locals {
  # Credential TTL: 300s (5 minutes)
  credential_ttl_seconds = 300

  # Maximum credential lifetime: 600s (10 minutes)
  credential_max_ttl_seconds = 600

  # VSO refreshes at 80% of TTL (240s) for smooth rotation with 60s overlap
  vso_refresh_after_seconds = local.credential_ttl_seconds * 0.8
  vso_refresh_after         = "${local.vso_refresh_after_seconds}s"
}
