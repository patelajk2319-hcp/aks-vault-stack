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

# -----------------------------------------------------------------------------
# Post-Deployment Instructions
# -----------------------------------------------------------------------------

output "next_steps" {
  description = "Instructions for using VSO"
  value       = <<-EOT
    Vault Secrets Operator has been deployed successfully.

    To use VSO to sync secrets from Vault to Kubernetes:

    1. Enable Kubernetes auth in Vault:
       kubectl exec -n ${var.namespace} vault-0 -- vault auth enable kubernetes
       kubectl exec -n ${var.namespace} vault-0 -- vault write auth/kubernetes/config \
           kubernetes_host="https://kubernetes.default.svc:443"

    2. Create a VaultAuth resource to configure authentication
    3. Create VaultStaticSecret or VaultDynamicSecret resources to sync secrets

    See VSO documentation: https://github.com/hashicorp/vault-secrets-operator
  EOT
}
