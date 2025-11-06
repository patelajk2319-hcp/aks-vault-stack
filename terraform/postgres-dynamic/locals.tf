# =============================================================================
# Local Values
# Centralised configuration for credential TTLs and timing
# =============================================================================

locals {
  # Credential TTL in seconds (5 minutes)
  # This controls how long each dynamic credential remains valid
  credential_ttl_seconds = 300

  # Maximum TTL in seconds (10 minutes)
  # Absolute maximum lifetime for credentials, even if renewed
  credential_max_ttl_seconds = 600

  # VSO refresh timing calculation
  # Refresh at 80% of TTL to provide 1-minute overlap for zero-downtime rotation
  # Formula: credential_ttl_seconds * 0.8
  # Example: 300s * 0.8 = 240s (4 minutes)
  # This creates a 60s overlap where both old and new credentials are valid
  vso_refresh_after_seconds = local.credential_ttl_seconds * 0.8

  # Format as Kubernetes duration string (e.g., "240s")
  vso_refresh_after = "${local.vso_refresh_after_seconds}s"
}
