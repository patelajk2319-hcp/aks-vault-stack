#!/bin/bash

# =============================================================================
# Deploy AKS Infrastructure Only
# This script deploys the Azure Kubernetes Service cluster infrastructure
# =============================================================================

set -e

# Source centralised colour configuration
source "$(dirname "$0")/lib/colors.sh"

# -----------------------------------------------------------------------------
# Load environment variables from .env file
# Required variables: ARM_SUBSCRIPTION_ID, ARM_TENANT_ID
# -----------------------------------------------------------------------------
if [ -f "$(dirname "$0")/../.env" ]; then
  echo -e "${BLUE}Loading environment variables from .env file...${NC}"
  set -a  # Automatically export all variables
  source "$(dirname "$0")/../.env"
  set +a  # Disable automatic export
  echo -e "${GREEN}✓ Environment variables loaded${NC}"
  echo ""
else
  echo -e "${RED}Error: .env file not found${NC}"
  echo "Please create a .env file with required variables:"
  echo "  ARM_SUBSCRIPTION_ID, ARM_TENANT_ID"
  exit 1
fi

# Validate required environment variables
if [ -z "$ARM_SUBSCRIPTION_ID" ] || [ -z "$ARM_TENANT_ID" ]; then
  echo -e "${RED}Error: Required Azure credentials not set in .env${NC}"
  echo "Please set ARM_SUBSCRIPTION_ID and ARM_TENANT_ID in .env file"
  exit 1
fi

# Export Terraform variables
export TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
export TF_VAR_tenant_id="$ARM_TENANT_ID"

echo -e "${BLUE}=== Deploying AKS Infrastructure ===${NC}"
echo ""

# -----------------------------------------------------------------------------
# Deploy AKS Infrastructure
# -----------------------------------------------------------------------------
echo -e "${BLUE}Deploying AKS Infrastructure${NC}"
cd "$(dirname "$0")/../terraform/aks"

# Initialise Terraform
echo -e "${BLUE}Initialising Terraform (AKS)...${NC}"
terraform init -upgrade

# Apply Terraform configuration
echo -e "${BLUE}Applying Terraform configuration (AKS)...${NC}"
terraform apply -auto-approve

echo ""
echo -e "${GREEN}✓ AKS Infrastructure deployed successfully${NC}"
echo ""

# Get AKS credentials
echo -e "${BLUE}Configuring kubectl for AKS...${NC}"
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)

az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --admin --overwrite-existing

echo -e "${GREEN}✓ kubectl configured for AKS cluster${NC}"
echo ""

echo ""
echo -e "${GREEN}=== AKS Infrastructure Deployment Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. ${BLUE}task up${NC}      - Deploy Vault to the AKS cluster"
echo -e "  2. ${BLUE}task init${NC}    - Initialise Vault (creates unseal keys and root token)"
echo -e "  3. ${BLUE}task unseal${NC}  - Unseal Vault and start port forwarding"
echo -e "  4. ${BLUE}task vso${NC}     - Deploy Vault Secrets Operator"
echo ""
