#!/bin/bash

# =============================================================================
# Deploy Core Infrastructure
# This script deploys AKS cluster and PostgreSQL database
# =============================================================================

set -e

# Source centralised colour configuration
source "$(dirname "$0")/lib/colors.sh"

# -----------------------------------------------------------------------------
# Load environment variables from .env file
# Required variables: ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, POSTGRES_ADMIN_PASSWORD
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
  echo "  ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, POSTGRES_ADMIN_PASSWORD"
  exit 1
fi

# Validate required environment variables
if [ -z "$ARM_SUBSCRIPTION_ID" ] || [ -z "$ARM_TENANT_ID" ]; then
  echo -e "${RED}Error: Required Azure credentials not set in .env${NC}"
  echo "Please set ARM_SUBSCRIPTION_ID and ARM_TENANT_ID in .env file"
  exit 1
fi

# Check for PostgreSQL admin password
if [ -z "$POSTGRES_ADMIN_PASSWORD" ]; then
  echo -e "${RED}Error: POSTGRES_ADMIN_PASSWORD not set in .env${NC}"
  echo "Please set POSTGRES_ADMIN_PASSWORD in .env file"
  exit 1
fi

# Export Terraform variables
export TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
export TF_VAR_tenant_id="$ARM_TENANT_ID"
export TF_VAR_postgres_admin_password="$POSTGRES_ADMIN_PASSWORD"

echo -e "${BLUE}=== Deploying Core Infrastructure ===${NC}"
echo ""

# -----------------------------------------------------------------------------
# Deploy Core Infrastructure (AKS + PostgreSQL)
# -----------------------------------------------------------------------------
echo -e "${BLUE}Deploying Core Infrastructure (AKS + PostgreSQL)${NC}"
cd "$(dirname "$0")/../terraform/core-infra"

# Initialise Terraform
echo -e "${BLUE}Initialising Terraform (Core Infrastructure)...${NC}"
terraform init -upgrade

# Apply Terraform configuration
echo -e "${BLUE}Applying Terraform configuration (AKS + PostgreSQL)...${NC}"
terraform apply -auto-approve

echo ""
echo -e "${GREEN}✓ Core Infrastructure deployed successfully${NC}"
echo ""

# Get AKS credentials
echo -e "${BLUE}Configuring kubectl for AKS...${NC}"
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)

az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --admin --overwrite-existing

echo -e "${GREEN}✓ kubectl configured for AKS cluster${NC}"
echo ""

# Display PostgreSQL information
echo -e "${BLUE}PostgreSQL Database Information:${NC}"
echo "  Server: $(terraform output -raw postgres_server_fqdn)"
echo "  Database: $(terraform output -raw postgres_database_name)"
echo ""

echo ""
echo -e "${GREEN}=== Core Infrastructure Deployment Complete! ===${NC}"
echo ""
