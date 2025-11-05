# =============================================================================
# AKS Module Variables
# This module creates a production-ready AKS cluster with:
# - System and user node pools
# - Azure CNI networking
# - Workload Identity and OIDC
# - Key Vault secrets provider
# - Container Insights monitoring
# =============================================================================

# -----------------------------------------------------------------------------
# Basic Cluster Configuration
# -----------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "subnet_id" {
  description = "The ID of the subnet for AKS nodes"
  type        = string
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
}

variable "dns_service_ip" {
  description = "IP address for the Kubernetes DNS service"
  type        = string
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  type        = string
}

# -----------------------------------------------------------------------------
# System Node Pool Configuration
# System node pools run critical cluster components (CoreDNS, metrics-server)
# -----------------------------------------------------------------------------

variable "system_node_count" {
  description = "Number of nodes in the system node pool"
  type        = number
}

variable "system_node_vm_size" {
  description = "VM size for system nodes"
  type        = string
}

variable "system_node_min_count" {
  description = "Minimum number of nodes in system pool when autoscaling is enabled"
  type        = number
}

variable "system_node_max_count" {
  description = "Maximum number of nodes in system pool when autoscaling is enabled"
  type        = number
}

variable "enable_auto_scaling" {
  description = "Enable autoscaling for node pools"
  type        = bool
}

# -----------------------------------------------------------------------------
# User Node Pool Configuration
# User node pools run application workloads
# -----------------------------------------------------------------------------

variable "create_user_node_pool" {
  description = "Whether to create a user node pool"
  type        = bool
}

variable "user_node_count" {
  description = "Number of nodes in the user node pool"
  type        = number
}

variable "user_node_vm_size" {
  description = "VM size for user nodes"
  type        = string
}

variable "user_node_min_count" {
  description = "Minimum number of nodes in user pool when autoscaling is enabled"
  type        = number
}

variable "user_node_max_count" {
  description = "Maximum number of nodes in user pool when autoscaling is enabled"
  type        = number
}

# -----------------------------------------------------------------------------
# Resource Tagging
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
