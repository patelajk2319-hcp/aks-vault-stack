#!/bin/bash

# =============================================================================
# Deploy Vault Secrets Operator
# This script deploys VSO to the AKS cluster
# IMPORTANT: Vault must be initialised and unsealed before running this
# =============================================================================

set -e

# Source centralised colour configuration
source "$(dirname "$0")/lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"

echo -e "${BLUE}=== Deploying Vault Secrets Operator ===${NC}"
echo ""

# Check if Vault is initialised
if [ ! -f vault-init.json ]; then
  echo -e "${RED}Error: vault-init.json not found${NC}"
  echo "Run 'task init' first to initialise Vault"
  exit 1
fi

# Check if Vault is unsealed
echo -e "${BLUE}Checking Vault status...${NC}"
VAULT_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$VAULT_POD" ]; then
  echo -e "${RED}Error: No Vault pod found in namespace $NAMESPACE${NC}"
  exit 1
fi

SEALED=$(kubectl exec -n "$NAMESPACE" "$VAULT_POD" -- vault status -format=json 2>/dev/null | jq -r '.sealed' || echo "true")

if [ "$SEALED" = "true" ]; then
  echo -e "${RED}Error: Vault is sealed${NC}"
  echo "Run 'task unseal' first to unseal Vault"
  exit 1
fi

echo -e "${GREEN}✓ Vault is unsealed and ready${NC}"
echo ""

# Deploy VSO
echo -e "${BLUE}Deploying VSO to AKS...${NC}"
cd "$(dirname "$0")/../terraform/vso"

# Check if terraform.tfvars exists, if not create it
if [ ! -f terraform.tfvars ]; then
  echo -e "${BLUE}Creating terraform.tfvars...${NC}"

  # Create terraform.tfvars for VSO deployment
  # Note: Providers use kubeconfig, no need to pass credentials
  cat > terraform.tfvars <<EOF
# VSO Configuration
namespace           = "vault"
vso_chart_version   = "0.9.0"
vault_service_name  = "vault"
EOF
fi

# Initialize Terraform
echo -e "${BLUE}Initializing Terraform (VSO)...${NC}"
terraform init -upgrade

# Apply Terraform configuration
echo -e "${BLUE}Applying Terraform configuration (VSO)...${NC}"
terraform apply -auto-approve

echo ""
echo -e "${GREEN}✓ VSO deployed successfully${NC}"
echo ""

# Wait for VSO pods to be ready
echo -e "${BLUE}Waiting for VSO pods to be ready...${NC}"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=vault-secrets-operator -n "$NAMESPACE" --timeout=300s || true

echo ""
echo -e "${GREEN}=== VSO Deployment Complete! ===${NC}"
echo ""
