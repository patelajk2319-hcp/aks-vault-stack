# =============================================================================
# VNet Module Variables
# This module creates an Azure Virtual Network with a dedicated subnet for AKS
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

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for the AKS subnet"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
