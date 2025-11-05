# -----------------------------------------------------------------------------
# Azure Log Analytics Workspace
# Central repository for all cluster logs, metrics, and diagnostic data
# -----------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "aks_logs" {
  name                = "${var.cluster_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018" # Pay-per-GB pricing model
  retention_in_days   = var.log_retention_days

  tags = var.tags
}
