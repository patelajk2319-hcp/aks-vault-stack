# =============================================================================
# VNet Module Outputs
# Exposes network resource IDs and names for use by the AKS module
# =============================================================================

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.aks_vnet.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.aks_vnet.name
}

output "subnet_id" {
  description = "The ID of the AKS subnet"
  value       = azurerm_subnet.aks_subnet.id
}

output "subnet_name" {
  description = "The name of the AKS subnet"
  value       = azurerm_subnet.aks_subnet.name
}
