# =============================================================================
# VSO Deployment Outputs
# Exposes information about the deployed Vault Secrets Operator
# =============================================================================

# -----------------------------------------------------------------------------
# Helm Release Information
# -----------------------------------------------------------------------------

output "vso_release_name" {
  description = "Name of the VSO Helm release"
  value       = helm_release.vault_secrets_operator.name
}

output "vso_chart_version" {
  description = "Version of the VSO Helm chart deployed"
  value       = helm_release.vault_secrets_operator.version
}

output "vso_namespace" {
  description = "Namespace where VSO is deployed"
  value       = var.namespace
}

# -----------------------------------------------------------------------------
# Connection Information
# -----------------------------------------------------------------------------

output "vault_connection_address" {
  description = "Vault address that VSO connects to"
  value       = "http://${var.vault_service_name}.${var.namespace}.svc.cluster.local:8200"
}
