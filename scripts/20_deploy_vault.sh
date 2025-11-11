#!/bin/bash

# =============================================================================
# Deploy Vault to Existing AKS Cluster
# This script deploys Vault to an already running AKS cluster
# =============================================================================

set -euo pipefail

# Source centralised colour configuration
source "$(dirname "$0")/lib/colors.sh"
source "$(dirname "$0")/lib/kubectl_context.sh"

echo -e "${BLUE}=== Deploying Vault to AKS ===${NC}"
echo ""

# Verify kubectl is configured and switch to correct context
if ! kubectl cluster-info &>/dev/null; then
  echo -e "${RED}Error: kubectl is not configured or cluster is not accessible${NC}"
  echo "Please ensure AKS cluster is deployed and kubectl is configured"
  exit 1
fi

ensure_correct_kubectl_context "$(dirname "$0")" || exit 1
echo ""

# -----------------------------------------------------------------------------
# Deploy Vault
# -----------------------------------------------------------------------------
echo -e "${BLUE}Deploying Vault to AKS${NC}"
cd "$(dirname "$0")/../terraform/vault"

# Initialise Terraform
echo -e "${BLUE}Initialising Terraform (Vault)...${NC}"
terraform init -upgrade

echo -e "${BLUE}Applying Terraform configuration (Vault)...${NC}"
terraform apply -auto-approve

echo ""
echo -e "${GREEN}✓ Vault deployed successfully${NC}"
echo ""

# Wait for Vault pods to be ready
echo -e "${BLUE}Waiting for Vault pods to be ready...${NC}"
echo -e "${YELLOW}Note: Pods will not be fully ready until Vault is initialised and unsealed${NC}"

# Check pod status with timeout
MAX_WAIT=60
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
  POD_STATUS=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")

  if [ "$POD_STATUS" = "Running" ]; then
    echo -e "${GREEN}✓ Vault pod is running (sealed state is expected)${NC}"
    break
  fi

  if [ $((ELAPSED % 10)) -eq 0 ]; then
    echo -e "${BLUE}  Vault pod status: ${POD_STATUS:-Pending} (${ELAPSED}s elapsed)${NC}"
  fi

  sleep 2
  ELAPSED=$((ELAPSED + 2))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
  echo -e "${YELLOW}Warning: Vault pod did not reach Running state within ${MAX_WAIT}s${NC}"
  echo -e "${YELLOW}This may be normal - proceed with 'task init' to initialise Vault${NC}"
fi

echo ""
echo -e "${GREEN}=== Vault Deployment Complete! ===${NC}"
echo ""
