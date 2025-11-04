# =============================================================================
# Vault Deployment Outputs
# Exposes information about the deployed Vault and VSO instances
# =============================================================================

# -----------------------------------------------------------------------------
# Namespace Information
# -----------------------------------------------------------------------------

output "namespace" {
  description = "Kubernetes namespace where Vault is deployed"
  value       = kubernetes_namespace.vault.metadata[0].name
}

# -----------------------------------------------------------------------------
# Vault Service Information
# -----------------------------------------------------------------------------

output "vault_service_name" {
  description = "Name of the Vault Kubernetes service"
  value       = "${helm_release.vault.name}.${kubernetes_namespace.vault.metadata[0].name}.svc.cluster.local"
}

output "vault_service_url" {
  description = "Internal URL to access Vault from within the cluster"
  value       = "http://${helm_release.vault.name}.${kubernetes_namespace.vault.metadata[0].name}.svc.cluster.local:8200"
}

output "vault_ui_url" {
  description = "URL for Vault UI (requires port-forward for external access)"
  value       = "http://${helm_release.vault.name}.${kubernetes_namespace.vault.metadata[0].name}.svc.cluster.local:8200/ui"
}

# -----------------------------------------------------------------------------
# Helm Release Information
# -----------------------------------------------------------------------------

output "vault_release_name" {
  description = "Name of the Vault Helm release"
  value       = helm_release.vault.name
}

output "vault_chart_version" {
  description = "Version of the Vault Helm chart deployed"
  value       = helm_release.vault.version
}

# -----------------------------------------------------------------------------
# Post-Deployment Instructions
# -----------------------------------------------------------------------------

output "vault_init_command" {
  description = "Command to initialize Vault (run after deployment)"
  value       = "kubectl exec -n ${kubernetes_namespace.vault.metadata[0].name} ${helm_release.vault.name}-0 -- vault operator init"
}

output "vault_status_command" {
  description = "Command to check Vault status"
  value       = "kubectl exec -n ${kubernetes_namespace.vault.metadata[0].name} ${helm_release.vault.name}-0 -- vault status"
}

output "port_forward_command" {
  description = "Command to access Vault UI via port forwarding"
  value       = "kubectl port-forward -n ${kubernetes_namespace.vault.metadata[0].name} svc/${helm_release.vault.name} 8200:8200"
}

output "next_steps" {
  description = "Instructions for initializing and unsealing Vault"
  value       = <<-EOT
    Vault has been deployed successfully!

    Next steps:
      1. Run 'task init' to initialize Vault
      2. Run 'task unseal' to unseal Vault and start port forwarding
      3. Run 'task vso' to deploy Vault Secrets Operator (after Vault is initialized)

    Access Vault UI at: http://localhost:8200/ui
  EOT
}
