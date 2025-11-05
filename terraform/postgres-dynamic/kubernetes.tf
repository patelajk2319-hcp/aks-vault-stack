# =============================================================================
# Kubernetes Manifests for VSO Dynamic Credentials
# Deploys VaultConnection, VaultAuth, and VaultDynamicSecret resources
# IMPORTANT: kubernetes_manifest takes object directly (not yamlencode)
# =============================================================================

# -----------------------------------------------------------------------------
# VaultConnection - Vault Server Connection
# Configures connection details for Vault server
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "vault_connection" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultConnection"
    metadata = {
      name      = "vault-connection"
      namespace = var.namespace
    }
    spec = {
      address       = "http://vault.${var.namespace}.svc.cluster.local:8200"
      skipTLSVerify = true
    }
  }

  depends_on = [
    vault_jwt_auth_backend.jwt,
    vault_policy.vso
  ]
}

# -----------------------------------------------------------------------------
# VaultAuth - JWT Authentication Configuration
# Configures how VSO authenticates to Vault using service account JWT tokens
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "vault_auth" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultAuth"
    metadata = {
      name      = "vault-auth"
      namespace = var.namespace
    }
    spec = {
      vaultConnectionRef = kubernetes_manifest.vault_connection.manifest.metadata.name
      method             = "jwt"
      mount              = vault_jwt_auth_backend.jwt.path
      jwt = {
        role           = vault_jwt_auth_backend_role.vso.role_name
        serviceAccount = "vault-secrets-operator-controller-manager"
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
# VaultDynamicSecret - PostgreSQL Dynamic Credentials
# Syncs dynamic database credentials from Vault to Kubernetes secrets
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "vault_dynamic_secret" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultDynamicSecret"
    metadata = {
      name      = "postgres-dynamic-creds"
      namespace = var.namespace
    }
    spec = {
      mount        = vault_mount.database.path
      path         = "creds/${vault_database_secret_backend_role.postgres.name}"
      vaultAuthRef = kubernetes_manifest.vault_auth.manifest.metadata.name
      destination = {
        name   = "postgres-dynamic-creds"
        create = true
      }
      refreshAfter = "240s"
    }
  }

  depends_on = [
    kubernetes_manifest.vault_auth,
    vault_database_secret_backend_role.postgres
  ]
}
