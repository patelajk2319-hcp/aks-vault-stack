
# -----------------------------------------------------------------------------
# Resource Group Outputs
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.aks_rg.name
}

# -----------------------------------------------------------------------------
# AKS Cluster Outputs
# Core cluster information including identities needed for workload identity
# -----------------------------------------------------------------------------

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.aks_cluster_name
}

output "aks_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = module.aks.aks_cluster_id
}

output "aks_cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = module.aks.aks_cluster_fqdn
}

output "aks_cluster_identity" {
  description = "The managed identity of the AKS cluster"
  value       = module.aks.aks_cluster_identity
}

output "aks_kubelet_identity" {
  description = "The kubelet identity of the AKS cluster"
  value       = module.aks.aks_kubelet_identity
}

output "aks_oidc_issuer_url" {
  description = "The OIDC issuer URL for workload identity"
  value       = module.aks.aks_oidc_issuer_url
}

# -----------------------------------------------------------------------------
# Kubernetes Configuration Outputs
# Sensitive outputs containing kubeconfig data
# These are marked sensitive to prevent accidental exposure in logs
# -----------------------------------------------------------------------------

output "kube_config" {
  description = "Kubeconfig for the AKS cluster"
  value       = module.aks.kube_config
  sensitive   = true
}

output "kube_admin_config" {
  description = "Admin kubeconfig for the AKS cluster"
  value       = module.aks.kube_admin_config
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Monitoring Outputs
# -----------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = module.logs.log_analytics_workspace_id
}

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = module.vnet.vnet_id
}

output "subnet_id" {
  description = "The ID of the AKS subnet"
  value       = module.vnet.subnet_id
}

# -----------------------------------------------------------------------------
# Helper Outputs
# Useful commands for working with the deployed cluster
# -----------------------------------------------------------------------------

output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks_rg.name} --name ${module.aks.aks_cluster_name}"
}
