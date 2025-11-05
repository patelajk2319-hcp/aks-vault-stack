
# -----------------------------------------------------------------------------
# Azure Virtual Network
# Provides isolated network space for AKS cluster resources
# The address space must be large enough to accommodate all subnets
# -----------------------------------------------------------------------------
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "${var.cluster_name}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_address_space]

  tags = var.tags
}

# -----------------------------------------------------------------------------
# AKS Subnet
# Dedicated subnet for AKS nodes and pods
# This subnet will be delegated to AKS for IP allocation
# Size should accommodate all nodes + pods (depends on CNI mode)
# -----------------------------------------------------------------------------
resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.cluster_name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = [var.aks_subnet_address_prefix]
}
