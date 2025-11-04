# =============================================================================
# Log Analytics Module Outputs
# Exposes workspace information for integration with AKS monitoring
# =============================================================================

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.aks_logs.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.aks_logs.name
}
