

# Vault Secrets Operator Helm Chart
resource "helm_release" "vault_secrets_operator" {
  name       = "vault-secrets-operator"
  repository = "https://helm.releases.hashicorp.com" 
  chart      = "vault-secrets-operator" 
  version    = var.vso_chart_version
  namespace  = var.namespace

  # Wait for VSO to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 300

  # Use values file from helm-chart directory
  # Vault connection configuration is in the values file
  values = [
    file("${path.root}/../../helm-chart/vault-stack/values/vso/vault-secrets-operator.yaml"),
    yamlencode({
      defaultVaultConnection = {
        enabled       = true
        address       = "http://${var.vault_service_name}.${var.namespace}.svc.cluster.local:8200"
        skipTLSVerify = true
      }
    })
  ]
}
