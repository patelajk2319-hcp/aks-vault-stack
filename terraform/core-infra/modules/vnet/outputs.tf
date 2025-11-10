# =============================================================================
# VNet Module Outputs
# Exposes network resource IDs for use by the AKS module
# =============================================================================

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.aks_vnet.id
}

output "subnet_id" {
  description = "The ID of the AKS subnet"
  value       = azurerm_subnet.aks_subnet.id
}
