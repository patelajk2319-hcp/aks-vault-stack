# =============================================================================
# Local Values
# Computed values used across the infrastructure configuration
# =============================================================================

# Generate a unique suffix for cluster name to ensure uniqueness across deployments
resource "random_id" "cluster_suffix" {
  byte_length = 4
}

# Construct unique cluster name and DNS prefix using prefix + random suffix
locals {
  cluster_name = "${var.cluster_name_prefix}-${random_id.cluster_suffix.hex}"
  dns_prefix   = "${var.cluster_name_prefix}-${random_id.cluster_suffix.hex}"
}
