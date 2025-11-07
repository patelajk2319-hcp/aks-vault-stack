# Outputs

output "jwt_auth_path" {
  description = "Path where JWT auth backend is mounted"
  value       = vault_jwt_auth_backend.wrkld1.path
}

output "jwt_role_name" {
  description = "Name of the JWT authentication role"
  value       = vault_jwt_auth_backend_role.wrkld1.role_name
}

output "service_account_name" {
  description = "Name of the Kubernetes ServiceAccount"
  value       = kubernetes_service_account.account.metadata[0].name
}

output "namespace" {
  description = "Kubernetes namespace where ServiceAccount is deployed"
  value       = var.namespace
}

output "policy_name" {
  description = "Name of the Vault policy"
  value       = vault_policy.wrkld1.name
}
