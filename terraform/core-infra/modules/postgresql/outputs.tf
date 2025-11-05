# =============================================================================
# PostgreSQL Module Outputs
# Exposes information about the PostgreSQL server
# =============================================================================

output "server_id" {
  description = "ID of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "database_name" {
  description = "Name of the application database"
  value       = azurerm_postgresql_flexible_server_database.app.name
}

output "admin_username" {
  description = "Administrator username"
  value       = var.admin_username
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = "host=${azurerm_postgresql_flexible_server.main.fqdn} port=5432 dbname=${azurerm_postgresql_flexible_server_database.app.name} user=${var.admin_username} sslmode=require"
  sensitive   = true
}
