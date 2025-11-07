# =============================================================================
# VSO Kubernetes Manifests for Workload 1
# Deploys VaultConnection, VaultAuth, and VaultDynamicSecret resources
# Connects workload to Vault for dynamic PostgreSQL credentials
# =============================================================================

# -----------------------------------------------------------------------------
# VaultConnection - Vault server connection details
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "vault_connection" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultConnection"
    metadata = {
      name      = "vault-connection-wrkld1"
      namespace = var.namespace
    }
    spec = {
      address       = "http://vault.${var.namespace}.svc.cluster.local:8200"
      skipTLSVerify = true
    }
  }

  depends_on = [
    vault_jwt_auth_backend.wrkld1
  ]
}

# -----------------------------------------------------------------------------
# VaultAuth - JWT authentication using wrkld1 ServiceAccount
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "vault_auth" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultAuth"
    metadata = {
      name      = "vault-auth-wrkld1"
      namespace = var.namespace
    }

    spec = {
      vaultConnectionRef = kubernetes_manifest.vault_connection.manifest.metadata.name

      # Use JWT auth method configured in this module
      method = "jwt"
      mount  = vault_jwt_auth_backend.wrkld1.path

      jwt = {
        role           = vault_jwt_auth_backend_role.wrkld1.role_name
        serviceAccount = kubernetes_service_account.account.metadata[0].name
        audiences = [
          "https://kubernetes.default.svc.cluster.local"
        ]
      }
    }
  }

  depends_on = [
    kubernetes_manifest.vault_connection
  ]
}

# -----------------------------------------------------------------------------
# VaultDynamicSecret - Syncs PostgreSQL credentials to K8s secrets
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "vault_dynamic_secret" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultDynamicSecret"
    metadata = {
      name      = "postgres-dynamic-creds-wrkld1"
      namespace = var.namespace
    }
    spec = {
      mount        = var.database_mount_path
      path         = "creds/${var.database_role_name}"
      vaultAuthRef = kubernetes_manifest.vault_auth.manifest.metadata.name
      destination = {
        name   = "postgres-dynamic-creds-wrkld1"
        create = true
      }

      # Refresh at 80% of TTL for zero-downtime rotation (see locals.tf)
      refreshAfter = local.vso_refresh_after
    }
  }

  depends_on = [
    kubernetes_manifest.vault_auth
  ]
}
