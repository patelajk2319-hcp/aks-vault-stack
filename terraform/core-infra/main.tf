resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}


module "vnet" {
  source = "./modules/vnet"

  cluster_name              = local.cluster_name
  location                  = azurerm_resource_group.aks_rg.location
  resource_group_name       = azurerm_resource_group.aks_rg.name
  vnet_address_space        = var.vnet_address_space
  aks_subnet_address_prefix = var.aks_subnet_address_prefix
  tags                      = var.tags
}

module "logs" {
  source = "./modules/logs"

  cluster_name        = local.cluster_name
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  log_retention_days  = var.log_retention_days
  tags                = var.tags
}

module "aks" {
  source = "./modules/aks"

  # Basic cluster configuration
  cluster_name        = local.cluster_name
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = local.dns_prefix
  kubernetes_version  = var.kubernetes_version
  tenant_id           = "56f775a3-2540-4f05-ab58-72cd72d17d3e"

  # Network configuration - integrates with the VNet module
  subnet_id      = module.vnet.subnet_id
  service_cidr   = var.service_cidr
  dns_service_ip = var.dns_service_ip

  # Monitoring integration - connects to Log Analytics workspace
  log_analytics_workspace_id = module.logs.log_analytics_workspace_id

  # System node pool configuration (for critical cluster components)
  system_node_count     = var.system_node_count
  system_node_vm_size   = var.system_node_vm_size
  system_node_min_count = var.system_node_min_count
  system_node_max_count = var.system_node_max_count
  enable_auto_scaling   = var.enable_auto_scaling

  # User node pool configuration (for application workloads)
  create_user_node_pool = var.create_user_node_pool
  user_node_count       = var.user_node_count
  user_node_vm_size     = var.user_node_vm_size
  user_node_min_count   = var.user_node_min_count
  user_node_max_count   = var.user_node_max_count

  tags = var.tags
}

# -----------------------------------------------------------------------------
# PostgreSQL Database
# Azure Database for PostgreSQL Flexible Server for dynamic credentials demo
# -----------------------------------------------------------------------------
module "postgresql" {
  source = "./modules/postgresql"

  server_name               = "${local.cluster_name}-pg"
  resource_group_name       = azurerm_resource_group.aks_rg.name
  location                  = azurerm_resource_group.aks_rg.location
  admin_username            = var.postgres_admin_username
  admin_password            = var.postgres_admin_password
  database_name             = var.postgres_database_name
  aks_subnet_address_prefix = var.aks_subnet_address_prefix
  tags                      = var.tags

  depends_on = [module.vnet]

}
