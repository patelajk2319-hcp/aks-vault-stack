# =============================================================================
# JWT Authentication Configuration for Workload 1
# Configures Vault JWT auth method for Kubernetes workload authentication
# =============================================================================

# -----------------------------------------------------------------------------
# Kubernetes ServiceAccount - wrkld1
# -----------------------------------------------------------------------------
resource "kubernetes_service_account" "account" {
  metadata {
    name      = "wrkld1-svc-acc"
    namespace = var.namespace
  }
}

# -----------------------------------------------------------------------------
# JWT Auth Backend - Kubernetes workload authentication
# -----------------------------------------------------------------------------
resource "vault_jwt_auth_backend" "wrkld1" {
  path               = "jwt/wrkld1"
  type               = "jwt"
  description        = "JWT authentication for workload 1"
  oidc_discovery_url = var.oidc_issuer_url
  bound_issuer       = var.oidc_issuer_url
}

# -----------------------------------------------------------------------------
# JWT Role - wrkld1 service account authentication
# -----------------------------------------------------------------------------
resource "vault_jwt_auth_backend_role" "wrkld1" {
  backend        = vault_jwt_auth_backend.wrkld1.path
  role_name      = "wrkld1"
  token_policies = [vault_policy.wrkld1.name]

  bound_audiences = ["https://kubernetes.default.svc.cluster.local"]
  bound_subject   = "system:serviceaccount:${var.namespace}:${kubernetes_service_account.account.metadata[0].name}"

  user_claim    = "sub"
  role_type     = "jwt"
  token_ttl     = 3600 #Seconds
  token_max_ttl = 7200 #Seconds
}
