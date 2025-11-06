# -----------------------------------------------------------------------------
# Dedicated namespace for Vault resources
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.namespace

    labels = merge(
      {
        name = var.namespace
        app  = "vault"
      },
      var.tags
    )
  }
}

# -----------------------------------------------------------------------------
# Vault Enterprise License Secret
# -----------------------------------------------------------------------------
resource "kubernetes_secret" "vault_license" {
  metadata {
    name      = "vault-license"
    namespace = kubernetes_namespace.vault.metadata[0].name
  }

  data = {
    license = file("${path.root}/../../licenses/vault-enterprise/license.lic")
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace.vault
  ]
}

# Vault Enterprise Helm Chart Deployment
resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com" # Official HashiCorp Helm repository
  chart      = "vault"                               # Official Vault chart
  version    = var.vault_chart_version
  namespace  = kubernetes_namespace.vault.metadata[0].name

  # Wait for Vault to be ready before proceeding
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  # Use values file from helm-chart directory
  # All configuration (replicas, storage, image) is in the values file
  values = [
    file("${path.root}/../../helm-chart/vault-stack/values/vault/vault.yaml")
  ]

  depends_on = [
    kubernetes_namespace.vault,
    kubernetes_secret.vault_license
  ]
}

