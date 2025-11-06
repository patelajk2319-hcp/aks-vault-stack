#!/bin/bash

# =============================================================================
# Nuclear Option - Destroy ALL Infrastructure
# This script destroys EVERYTHING including AKS cluster
#
# WARNING: This is a destructive operation that cannot be undone!
# =============================================================================

set -euo pipefail

# Source centralised colour configuration
source "$(dirname "$0")/../lib/colors.sh"

echo -e "${BLUE}=== Destroying All Infrastructure ===${NC}"
echo -e "${YELLOW}This will remove: VSO, Vault, and AKS cluster${NC}"
echo ""

# -----------------------------------------------------------------------------
# Step 1: Clear the cluster (VSO, Vault)
# -----------------------------------------------------------------------------
echo -e "${BLUE}Step 1: Clearing cluster resources...${NC}"
echo ""

# Run the clear_aks_cluster script
"$(dirname "$0")/clear_aks_cluster.sh"

echo ""
echo -e "${GREEN}✓ Cluster resources cleared${NC}"
echo ""

# -----------------------------------------------------------------------------
# Step 2: Destroy Core Infrastructure (AKS + PostgreSQL)
# -----------------------------------------------------------------------------
echo -e "${BLUE}Step 2: Destroying core infrastructure (AKS + PostgreSQL)...${NC}"
cd "$(dirname "$0")/../../terraform/core-infra"

AKS_DESTROY_SUCCESS=false
if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
  # Load environment variables for Azure authentication
  if [ -f "$(dirname "$0")/../../.env" ]; then
    set -a
    source "$(dirname "$0")/../../.env"
    set +a

    # Export Terraform variables
    export TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
    export TF_VAR_tenant_id="$ARM_TENANT_ID"
    export TF_VAR_postgres_admin_password="$POSTGRES_ADMIN_PASSWORD"
  fi

  terraform init -upgrade 2>/dev/null || true
  if terraform destroy -auto-approve; then
    AKS_DESTROY_SUCCESS=true
    echo -e "${GREEN}✓ AKS infrastructure destroyed${NC}"
  else
    echo -e "${YELLOW}Warning: AKS destroy encountered issues${NC}"
  fi
else
  echo -e "${YELLOW}No AKS terraform state found, skipping...${NC}"
  AKS_DESTROY_SUCCESS=true
fi
echo ""

# -----------------------------------------------------------------------------
# Step 3: Clean up remaining core infrastructure files
# -----------------------------------------------------------------------------
echo -e "${BLUE}Step 3: Cleaning up remaining local files...${NC}"
cd "$(dirname "$0")/../.."

# Remove terraform.tfvars files
rm -f terraform/core-infra/terraform.tfvars
echo -e "${GREEN}  - Removed core-infra terraform.tfvars${NC}"

# Remove terraform lock files
rm -f terraform/core-infra/.terraform.lock.hcl
echo -e "${GREEN}  - Removed core-infra terraform lock files${NC}"

# Remove .terraform directories and state files only if destroy was successful
if [ "$AKS_DESTROY_SUCCESS" = true ]; then
  rm -rf terraform/core-infra/.terraform
  rm -f terraform/core-infra/terraform.tfstate*
  echo -e "${GREEN}  - Removed core-infra .terraform directory and state files${NC}"
fi

echo ""
echo -e "${GREEN}=== Infrastructure Destruction Complete! ===${NC}"
echo ""
