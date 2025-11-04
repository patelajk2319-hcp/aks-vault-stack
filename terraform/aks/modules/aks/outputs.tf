
# -----------------------------------------------------------------------------
# Basic Cluster Information
# -----------------------------------------------------------------------------

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

# -----------------------------------------------------------------------------
# Cluster Identity Information
# The cluster managed identity is used for Azure resource operations
# -----------------------------------------------------------------------------

output "aks_cluster_identity" {
  description = "The managed identity of the AKS cluster"
  value = {
    principal_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id
    tenant_id    = azurerm_kubernetes_cluster.aks.identity[0].tenant_id
    type         = azurerm_kubernetes_cluster.aks.identity[0].type
  }
}

# -----------------------------------------------------------------------------
# Kubelet Identity
# The kubelet identity is used by nodes to pull container images and access resources
# This is a separate identity from the cluster control plane identity
# -----------------------------------------------------------------------------

output "aks_kubelet_identity" {
  description = "The kubelet identity of the AKS cluster"
  value = {
    client_id                 = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
    object_id                 = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].user_assigned_identity_id
  }
}

# -----------------------------------------------------------------------------
# OIDC Issuer URL
# Required for setting up workload identity federated credentials
# Pods can use this to authenticate to Azure services without secrets
# -----------------------------------------------------------------------------

output "aks_oidc_issuer_url" {
  description = "The OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

# -----------------------------------------------------------------------------
# Kubernetes Configuration
# Sensitive outputs for cluster access
# -----------------------------------------------------------------------------

output "kube_config" {
  description = "Kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_admin_config" {
  description = "Admin kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive   = true
}
