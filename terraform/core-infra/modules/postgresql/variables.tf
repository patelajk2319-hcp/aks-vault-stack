# =============================================================================
# PostgreSQL Module Variables
# Configuration parameters for Azure Database for PostgreSQL Flexible Server
# =============================================================================

variable "server_name" {
  description = "Name of the PostgreSQL server"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "admin_username" {
  description = "Administrator username for PostgreSQL"
  type        = string
  default     = "pgadmin"
}

variable "admin_password" {
  description = "Administrator password for PostgreSQL"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Name of the application database"
  type        = string
  default     = "postgres-vault-database"
}

variable "aks_subnet_address_prefix" {
  description = "CIDR block of the AKS subnet for firewall rules"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
