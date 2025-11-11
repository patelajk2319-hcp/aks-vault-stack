# =============================================================================
# Azure Provider Configuration
# These variables configure the Azure and Azure AD providers
# =============================================================================

variable "subscription_id" {
  description = "Azure subscription ID for resource deployment (set via ARM_SUBSCRIPTION_ID env var from .env)"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure AD tenant ID for authentication (set via ARM_TENANT_ID env var from .env)"
  type        = string
  sensitive   = true
}

# =============================================================================
# Core Configuration Variables
# These variables define the fundamental settings for the AKS infrastructure
# =============================================================================

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-aks-vault-stack"
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "uksouth"
}

variable "cluster_name_prefix" {
  description = "Prefix for the AKS cluster name (a unique suffix will be automatically appended to ensure global uniqueness)"
  type        = string
  default     = "aks-vault"
}

# Note: dns_prefix is automatically derived from cluster_name_prefix + unique suffix
# No separate variable needed - see locals in main.tf

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.32.7"
}

# =============================================================================
# Network Configuration
# Defines the network architecture including VNet and subnet addressing
# Note: service_cidr and vnet_address_space must not overlap
# =============================================================================

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for the AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for the Kubernetes DNS service"
  type        = string
  default     = "10.1.0.10" # Must be within the service_cidr range
}

# =============================================================================
# System Node Pool Configuration
# System node pools host critical system pods like CoreDNS and metrics-server
# These nodes should always be available for cluster operations
# =============================================================================

variable "system_node_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 1
}

variable "system_node_vm_size" {
  description = "VM size for system nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "system_node_min_count" {
  description = "Minimum number of nodes in system pool when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "system_node_max_count" {
  description = "Maximum number of nodes in system pool when autoscaling is enabled"
  type        = number
  default     = 3
}

# =============================================================================
# User Node Pool Configuration
# User node pools are for running application workloads
# Can be scaled independently from system nodes
# =============================================================================

variable "create_user_node_pool" {
  description = "Whether to create a user node pool"
  type        = bool
  default     = true
}

variable "user_node_count" {
  description = "Number of nodes in the user node pool"
  type        = number
  default     = 1
}

variable "user_node_vm_size" {
  description = "VM size for user nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "user_node_min_count" {
  description = "Minimum number of nodes in user pool when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "user_node_max_count" {
  description = "Maximum number of nodes in user pool when autoscaling is enabled"
  type        = number
  default     = 2
}

# =============================================================================
# Autoscaling Configuration
# Controls whether node pools can automatically scale based on resource usage
# =============================================================================

variable "enable_auto_scaling" {
  description = "Enable autoscaling for node pools"
  type        = bool
  default     = true
}

# =============================================================================
# Monitoring Configuration
# Settings for Azure Monitor and Log Analytics integration
# =============================================================================

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics"
  type        = number
  default     = 30
}

# =============================================================================
# Resource Tagging
# Tags applied to all resources for organisation and cost tracking
# =============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    environment = "demo"
    project     = "aks-vault-stack"
    managed_by  = "terraform"
  }
}

# =============================================================================
# PostgreSQL Configuration
# Settings for Azure Database for PostgreSQL Flexible Server
# =============================================================================

variable "postgres_admin_username" {
  description = "Administrator username for PostgreSQL"
  type        = string
  default     = "pgadmin"
}

variable "postgres_admin_password" {
  description = "Administrator password for PostgreSQL"
  type        = string
  sensitive   = true
}

variable "postgres_database_name" {
  description = "Name of the application database"
  type        = string
  default     = "postgres-vault-database"
}
