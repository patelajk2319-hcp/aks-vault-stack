# =============================================================================
# Log Analytics Module Variables
# This module creates a Log Analytics workspace for AKS monitoring
# Enables Container Insights for cluster observability
# =============================================================================

variable "cluster_name" {
  description = "The name of the AKS cluster (used for naming)"
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

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
