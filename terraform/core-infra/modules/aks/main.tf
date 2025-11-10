
# AKS cluster with system node pool
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  # System node pool - required cluster component
  default_node_pool {
    name                 = "system"
    node_count           = var.system_node_count
    vm_size              = var.system_node_vm_size
    vnet_subnet_id       = var.subnet_id
    type                 = "VirtualMachineScaleSets"
    auto_scaling_enabled = var.enable_auto_scaling
    min_count            = var.enable_auto_scaling ? var.system_node_min_count : null
    max_count            = var.enable_auto_scaling ? var.system_node_max_count : null
    max_pods             = 110
    os_disk_size_gb      = 128

    # Upgrade strategy for zero-downtime updates
    upgrade_settings {
      max_surge = "10%"
    }

    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  # Azure CNI - pods receive VNet IPs
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
    load_balancer_sku = "standard"
  }

  # Container Insights monitoring
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Managed Azure AD with RBAC for K8s authorisation
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = var.tenant_id
  }

  # CSI driver for Azure Key Vault secret rotation
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Workload Identity with OIDC for pod authentication
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  tags = var.tags

  # Ignore node_count changes (managed by autoscaler)
  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# Optional user node pool for application workloads
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
  max_pods              = 110
  os_disk_size_gb       = 128
  mode                  = "User"

  upgrade_settings {
    max_surge = "10%"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# Grant AKS identity permission to manage network resources
resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
