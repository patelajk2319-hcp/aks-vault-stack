# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server
# Using Burstable SKU with minimal resources (1 vCore, 2 GB RAM)
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "main" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location

  # Administrator credentials
  administrator_login    = var.admin_username
  administrator_password = var.admin_password

  # Version
  version = "16"

  # SKU - Smallest burstable instance (B1ms: 1 vCore, 2 GB RAM)
  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768 # 32 GB minimum
  zone       = "1"    # Keep in availability zone 1

  # Backup configuration
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  # Maintenance window
  maintenance_window {
    day_of_week  = 0
    start_hour   = 0
    start_minute = 0
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server Configuration
# Enable password authentication and configure PostgreSQL settings
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_configuration" "password_encryption" {
  name      = "password_encryption"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "md5"
}

# -----------------------------------------------------------------------------
# Firewall Rule to allow Azure services
# Allows connections from Azure services including AKS
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# -----------------------------------------------------------------------------
# Firewall Rule to allow AKS subnet
# Allows connections from AKS cluster
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_firewall_rule" "aks_subnet" {
  count            = var.aks_subnet_address_prefix != "" ? 1 : 0
  name             = "AllowAKSSubnet"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = cidrhost(var.aks_subnet_address_prefix, 0)
  end_ip_address   = cidrhost(var.aks_subnet_address_prefix, -1)
}

# -----------------------------------------------------------------------------
# PostgreSQL Database
# Create application database
# -----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
