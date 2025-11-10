#!/bin/bash

# Clear AKS Cluster - Removes VSO, Workload 1, and Vault

set -euo pipefail

source "$(dirname "$0")/../lib/colors.sh"

echo -e "${BLUE}=== Clearing AKS Cluster ===${NC}"
echo ""

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
  rm -f terraform/workload-1/terraform.tfvars 2>/dev/null || true
  rm -f terraform/vault-audit-devices/terraform.tfvars 2>/dev/null || true
  rm -f terraform/vault/.terraform.lock.hcl 2>/dev/null || true
  rm -f terraform/vso/.terraform.lock.hcl 2>/dev/null || true
  rm -f terraform/workload-1/.terraform.lock.hcl 2>/dev/null || true
  rm -f terraform/vault-audit-devices/.terraform.lock.hcl 2>/dev/null || true
  rm -rf terraform/vso/.terraform 2>/dev/null || true
  rm -f terraform/vso/terraform.tfstate* 2>/dev/null || true
  rm -rf terraform/vault/.terraform 2>/dev/null || true
  rm -f terraform/vault/terraform.tfstate* 2>/dev/null || true
  rm -rf terraform/vault-audit-devices/.terraform 2>/dev/null || true
  rm -f terraform/vault-audit-devices/terraform.tfstate* 2>/dev/null || true
  rm -rf terraform/workload-1/.terraform 2>/dev/null || true
  rm -f terraform/workload-1/terraform.tfstate* 2>/dev/null || true
  echo -e "${GREEN}✓ Local files cleaned${NC}"
  echo ""
  echo -e "${GREEN}=== Cleanup Complete! ===${NC}"
  exit 0
fi
echo -e "${GREEN}✓ Cluster is accessible${NC}"
echo ""

echo -e "${BLUE}Step 1: Stopping port-forwarding processes...${NC}"
pkill -f "kubectl port-forward.*vault" || true
echo -e "${GREEN}✓ Port-forwarding processes stopped${NC}"
echo ""

echo -e "${BLUE}Step 2: Destroying Workload 1...${NC}"
cd "$(dirname "$0")/../../terraform/workload-1"

WORKLOAD_DESTROY_SUCCESS=false
if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
  if [ -f "$(dirname "$0")/../../.env" ]; then
    source "$(dirname "$0")/../../.env"
  fi

  export TF_VAR_postgres_connection_url="postgresql://dummy:dummy@localhost:5432/dummy"
  export TF_VAR_oidc_issuer_url="https://dummy-issuer.local"

  terraform init -upgrade 2>/dev/null || true
  if terraform destroy -auto-approve -refresh=false 2>/dev/null; then
    WORKLOAD_DESTROY_SUCCESS=true
    echo -e "${GREEN}✓ Workload 1 destroyed${NC}"
  else
    echo -e "${YELLOW}Warning: Workload 1 destroy encountered issues${NC}"
  fi

  unset TF_VAR_postgres_connection_url
  unset TF_VAR_oidc_issuer_url
else
  echo -e "${YELLOW}No Workload 1 terraform state found, skipping...${NC}"
  WORKLOAD_DESTROY_SUCCESS=true
fi
echo ""

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

echo -e "${BLUE}Step 4: Destroying Vault audit devices...${NC}"
cd "$(dirname "$0")/../../terraform/vault-audit-devices"

AUDIT_DESTROY_SUCCESS=false
if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
  if [ -f "$(dirname "$0")/../../.env" ]; then
    source "$(dirname "$0")/../../.env"
  fi

  terraform init -upgrade 2>/dev/null || true
  if terraform destroy -auto-approve; then
    AUDIT_DESTROY_SUCCESS=true
    echo -e "${GREEN}✓ Audit devices destroyed${NC}"
  else
    echo -e "${YELLOW}Warning: Audit devices destroy encountered issues${NC}"
  fi
else
  echo -e "${YELLOW}No audit devices terraform state found, skipping...${NC}"
  AUDIT_DESTROY_SUCCESS=true
fi
echo ""

echo -e "${BLUE}Step 5: Destroying Vault infrastructure...${NC}"
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

echo -e "${BLUE}Step 6: Cleaning up local files...${NC}"
cd "$(dirname "$0")/../.."

rm -f vault-init.json
echo -e "${GREEN}  - Removed vault-init.json${NC}"

rm -f terraform/vault/terraform.tfvars
rm -f terraform/vso/terraform.tfvars
rm -f terraform/workload-1/terraform.tfvars
rm -f terraform/vault-audit-devices/terraform.tfvars
echo -e "${GREEN}  - Removed terraform.tfvars files${NC}"

rm -f terraform/vault/.terraform.lock.hcl
rm -f terraform/vso/.terraform.lock.hcl
rm -f terraform/workload-1/.terraform.lock.hcl
rm -f terraform/vault-audit-devices/.terraform.lock.hcl
echo -e "${GREEN}  - Removed terraform lock files${NC}"

if [ "$WORKLOAD_DESTROY_SUCCESS" = true ]; then
  rm -rf terraform/workload-1/.terraform
  rm -f terraform/workload-1/terraform.tfstate*
  echo -e "${GREEN}  - Removed workload-1 .terraform directory and state files${NC}"
fi

if [ "$VSO_DESTROY_SUCCESS" = true ]; then
  rm -rf terraform/vso/.terraform
  rm -f terraform/vso/terraform.tfstate*
  echo -e "${GREEN}  - Removed VSO .terraform directory and state files${NC}"
fi

if [ "$AUDIT_DESTROY_SUCCESS" = true ]; then
  rm -rf terraform/vault-audit-devices/.terraform
  rm -f terraform/vault-audit-devices/terraform.tfstate*
  echo -e "${GREEN}  - Removed audit-devices .terraform directory and state files${NC}"
fi

if [ "$VAULT_DESTROY_SUCCESS" = true ]; then
  rm -rf terraform/vault/.terraform
  rm -f terraform/vault/terraform.tfstate*
  echo -e "${GREEN}  - Removed Vault .terraform directory and state files${NC}"
fi

echo ""
echo -e "${GREEN}=== AKS Cluster Cleared! ===${NC}"
echo ""

