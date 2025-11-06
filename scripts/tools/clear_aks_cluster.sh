#!/bin/bash

# =============================================================================
# Clear AKS Cluster - Remove All Resources Without Destroying AKS
# This script removes all deployed resources from the AKS cluster:
# 1. Kill any port-forwarding processes
# 2. Destroy VSO
# 3. Destroy Vault
# 4. Clean up local files
#
# NOTE: This does NOT destroy the AKS cluster itself
# =============================================================================

set -e

# Source centralised colour configuration
source "$(dirname "$0")/../lib/colors.sh"

echo -e "${BLUE}=== Clearing AKS Cluster ===${NC}"
echo ""

# -----------------------------------------------------------------------------
# Pre-flight Check: Verify AKS cluster exists and is accessible
# -----------------------------------------------------------------------------
echo -e "${BLUE}Checking AKS cluster connectivity...${NC}"
if ! kubectl cluster-info &>/dev/null; then
  echo -e "${YELLOW}Warning: kubectl is not configured or cluster is not accessible${NC}"
  echo -e "${YELLOW}No cluster resources to clear${NC}"
  echo ""
  echo -e "${BLUE}Proceeding with local file cleanup only...${NC}"
  echo ""

  # Jump to cleanup step
  cd "$(dirname "$0")/../.."
  rm -f vault-init.json 2>/dev/null || true
  rm -f terraform/vault/terraform.tfvars 2>/dev/null || true
  rm -f terraform/vso/terraform.tfvars 2>/dev/null || true
  rm -f terraform/postgres-dynamic/terraform.tfvars 2>/dev/null || true
  rm -f terraform/vault/.terraform.lock.hcl 2>/dev/null || true
  rm -f terraform/vso/.terraform.lock.hcl 2>/dev/null || true
  rm -f terraform/postgres-dynamic/.terraform.lock.hcl 2>/dev/null || true
  rm -rf terraform/vso/.terraform 2>/dev/null || true
  rm -f terraform/vso/terraform.tfstate* 2>/dev/null || true
  rm -rf terraform/vault/.terraform 2>/dev/null || true
  rm -f terraform/vault/terraform.tfstate* 2>/dev/null || true
  rm -rf terraform/vault-config/.terraform 2>/dev/null || true
  rm -f terraform/vault-config/terraform.tfstate* 2>/dev/null || true
  echo -e "${GREEN}✓ Local files cleaned${NC}"
  echo ""
  echo -e "${GREEN}=== Cleanup Complete! ===${NC}"
  exit 0
fi
echo -e "${GREEN}✓ Cluster is accessible${NC}"
echo ""

# -----------------------------------------------------------------------------
# Step 1: Kill any port-forwarding processes
# -----------------------------------------------------------------------------
echo -e "${BLUE}Step 1: Stopping port-forwarding processes...${NC}"
pkill -f "kubectl port-forward.*vault" || true
echo -e "${GREEN}✓ Port-forwarding processes stopped${NC}"
echo ""

# -----------------------------------------------------------------------------
# Step 2: Destroy Vault Configuration (auth & secrets engines)
# -----------------------------------------------------------------------------
echo -e "${BLUE}Step 2: Destroying Vault configuration...${NC}"
cd "$(dirname "$0")/../../terraform/postgres-dynamic"

VAULT_CONFIG_DESTROY_SUCCESS=false
if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
  # Source .env for Vault credentials
  if [ -f "$(dirname "$0")/../../.env" ]; then
    source "$(dirname "$0")/../../.env"
  fi

  # Set dummy variables for destroy (actual values not needed for teardown)
  export TF_VAR_oidc_issuer_url="https://dummy-issuer.local"
  export TF_VAR_postgres_connection_url="postgresql://dummy:dummy@localhost:5432/dummy"

  terraform init -upgrade 2>/dev/null || true
  if terraform destroy -auto-approve; then
    VAULT_CONFIG_DESTROY_SUCCESS=true
    echo -e "${GREEN}✓ Vault configuration destroyed${NC}"
  else
    echo -e "${YELLOW}Warning: Vault configuration destroy encountered issues${NC}"
  fi

  # Clean up dummy variables
  unset TF_VAR_oidc_issuer_url
  unset TF_VAR_postgres_connection_url
else
  echo -e "${YELLOW}No Vault configuration terraform state found, skipping...${NC}"
  VAULT_CONFIG_DESTROY_SUCCESS=true
fi
echo ""

# -----------------------------------------------------------------------------
# Step 3: Destroy VSO
# -----------------------------------------------------------------------------
echo -e "${BLUE}Step 3: Destroying Vault Secrets Operator...${NC}"
cd "$(dirname "$0")/../../terraform/vso"

VSO_DESTROY_SUCCESS=false
if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
  terraform init -upgrade 2>/dev/null || true
  if terraform destroy -auto-approve; then
    VSO_DESTROY_SUCCESS=true
    echo -e "${GREEN}✓ VSO destroyed${NC}"
  else
    echo -e "${YELLOW}Warning: VSO destroy encountered issues${NC}"
  fi
else
  echo -e "${YELLOW}No VSO terraform state found, skipping...${NC}"
  VSO_DESTROY_SUCCESS=true
fi
echo ""

# -----------------------------------------------------------------------------
# Step 4: Destroy Vault
# -----------------------------------------------------------------------------
echo -e "${BLUE}Step 4: Destroying Vault infrastructure...${NC}"
cd "$(dirname "$0")/../../terraform/vault"

VAULT_DESTROY_SUCCESS=false
if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
  terraform init -upgrade 2>/dev/null || true
  if terraform destroy -auto-approve; then
    VAULT_DESTROY_SUCCESS=true
    echo -e "${GREEN}✓ Vault destroyed${NC}"
  else
    echo -e "${YELLOW}Warning: Vault destroy encountered issues${NC}"
  fi
else
  echo -e "${YELLOW}No Vault terraform state found, skipping...${NC}"
  VAULT_DESTROY_SUCCESS=true
fi
echo ""

# Delete Vault PVCs to ensure clean initialisation on next deployment
echo -e "${BLUE}Deleting Vault persistent volume claims...${NC}"
if kubectl get pvc -n vault &>/dev/null; then
  kubectl delete pvc --all -n vault --timeout=60s 2>/dev/null || true
  echo -e "${GREEN}✓ Vault PVCs deleted${NC}"
else
  echo -e "${YELLOW}No Vault PVCs found${NC}"
fi
echo ""

# -----------------------------------------------------------------------------
# Step 5: Clean up local files
# -----------------------------------------------------------------------------
echo -e "${BLUE}Step 5: Cleaning up local files...${NC}"
cd "$(dirname "$0")/../.."

# Remove Vault initialisation files
rm -f vault-init.json
echo -e "${GREEN}  - Removed vault-init.json${NC}"

# Remove terraform.tfvars files (but not core-infra)
rm -f terraform/vault/terraform.tfvars
rm -f terraform/vso/terraform.tfvars
rm -f terraform/vault-config/terraform.tfvars
echo -e "${GREEN}  - Removed terraform.tfvars files${NC}"

# Remove terraform lock files (but not core-infra)
rm -f terraform/vault/.terraform.lock.hcl
rm -f terraform/vso/.terraform.lock.hcl
rm -f terraform/vault-config/.terraform.lock.hcl
echo -e "${GREEN}  - Removed terraform lock files${NC}"

# Remove .terraform directories and state files only if destroy was successful
if [ "$VAULT_CONFIG_DESTROY_SUCCESS" = true ]; then
  rm -rf terraform/postgres-dynamic/.terraform
  rm -f terraform/postgres-dynamic/terraform.tfstate*
  echo -e "${GREEN}  - Removed Vault config .terraform directory and state files${NC}"
fi

if [ "$VSO_DESTROY_SUCCESS" = true ]; then
  rm -rf terraform/vso/.terraform
  rm -f terraform/vso/terraform.tfstate*
  echo -e "${GREEN}  - Removed VSO .terraform directory and state files${NC}"
fi

if [ "$VAULT_DESTROY_SUCCESS" = true ]; then
  rm -rf terraform/vault/.terraform
  rm -f terraform/vault/terraform.tfstate*
  echo -e "${GREEN}  - Removed Vault .terraform directory and state files${NC}"
fi

echo ""
echo -e "${GREEN}=== AKS Cluster Cleared! ===${NC}"
echo ""

