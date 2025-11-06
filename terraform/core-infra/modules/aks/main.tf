
# -----------------------------------------------------------------------------
# Azure Kubernetes Service Cluster
# Main cluster resource with system node pool
# -----------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  # ---------------------------------------------------------------------------
  # Default Node Pool (System)
  # System node pool is required and hosts critical system pods
  # Marked as "system" to ensure cluster components run here
  # Uses VirtualMachineScaleSets for reliability and scaling
  # ---------------------------------------------------------------------------
  default_node_pool {
    name                 = "system"
    node_count           = var.system_node_count
    vm_size              = var.system_node_vm_size
    vnet_subnet_id       = var.subnet_id
    type                 = "VirtualMachineScaleSets" # Required for production
    auto_scaling_enabled = var.enable_auto_scaling
    min_count            = var.enable_auto_scaling ? var.system_node_min_count : null
    max_count            = var.enable_auto_scaling ? var.system_node_max_count : null
    max_pods             = 110 # Maximum pods per node (Azure CNI default)
    os_disk_size_gb      = 128

    # Upgrade settings control rolling update behaviour during cluster upgrades
    upgrade_settings {
      max_surge = "10%" # Add 10% extra nodes during upgrades for zero-downtime
    }

    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  # ---------------------------------------------------------------------------
  # Network Profile
  # Azure CNI provides native VNet integration
  # Each pod gets an IP from the subnet
  # ---------------------------------------------------------------------------
  network_profile {
    network_plugin    = "azure" # Azure CNI (pods get VNet IPs)
    network_policy    = "azure" # Azure Network Policy for pod network rules
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr # Must not overlap with VNet CIDR
    load_balancer_sku = "standard"       # Standard LB required for production
  }

  # ---------------------------------------------------------------------------
  # Container Insights (OMS Agent)
  # Enables Azure Monitor for containers
  # Collects logs, metrics, and performance data
  # ---------------------------------------------------------------------------
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # ---------------------------------------------------------------------------
  # Azure AD Integration and RBAC
  # Managed AAD integration for Kubernetes authentication
  # Azure RBAC allows using Azure roles for Kubernetes authorization
  # ---------------------------------------------------------------------------
  azure_active_directory_role_based_access_control {
    # Managed AAD is now the default in AzureRM provider v4.0+
    azure_rbac_enabled = true # Use Azure RBAC for K8s authorisation
    tenant_id          = var.tenant_id
  }

  # ---------------------------------------------------------------------------
  # Key Vault Secrets Provider
  # CSI driver for mounting secrets from Azure Key Vault as volumes
  # Secret rotation automatically updates secrets in pods
  # ---------------------------------------------------------------------------
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m" # Check for secret updates every 2 minutes
  }

  # ---------------------------------------------------------------------------
  # Workload Identity
  # Enables Azure AD Workload Identity for pod authentication
  # OIDC issuer allows pods to get Azure AD tokens using federated credentials
  # This is the modern replacement for AAD Pod Identity
  # ---------------------------------------------------------------------------
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  tags = var.tags

  # ---------------------------------------------------------------------------
  # Lifecycle Management
  # Ignore node_count changes to prevent conflicts with autoscaling
  # Autoscaler manages node count, Terraform shouldn't override it
  # ---------------------------------------------------------------------------
  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# -----------------------------------------------------------------------------
# User Node Pool
# Optional dedicated node pool for application workloads
# Separating user workloads from system components improves reliability
# Can be scaled independently or deleted without affecting cluster operations
# -----------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count                 = var.create_user_node_pool ? 1 : 0
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.subnet_id
  auto_scaling_enabled  = var.enable_auto_scaling
  min_count             = var.enable_auto_scaling ? var.user_node_min_count : null
  max_count             = var.enable_auto_scaling ? var.user_node_max_count : null
  max_pods              = 110 # Maximum pods per node (Azure CNI default)
  os_disk_size_gb       = 128
  mode                  = "User" # User mode allows deletion without affecting cluster

  # Upgrade settings control rolling update behaviour during cluster upgrades
  upgrade_settings {
    max_surge = "10%" # Add 10% extra nodes during upgrades for zero-downtime
  }

  tags = var.tags

  # Ignore node_count changes to prevent conflicts with autoscaling
  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# -----------------------------------------------------------------------------
# Role Assignment: Network Contributor
# Grants the AKS cluster's managed identity permission to manage network resources
# Required for Azure CNI to:
# - Assign IPs to pods from the subnet
# - Create and manage load balancer rules
# - Update network security groups
# -----------------------------------------------------------------------------
resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
