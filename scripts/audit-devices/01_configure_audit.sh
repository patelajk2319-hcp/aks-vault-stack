#!/bin/bash

# =============================================================================
# Configure Vault Audit Device
# Enables file-based audit logging for Vault using Terraform
# IMPORTANT: Must run AFTER Vault is initialised and unsealed
# =============================================================================

set -euo pipefail

# Source centralised colour configuration
source "$(dirname "$0")/../lib/colors.sh"
source "$(dirname "$0")/../lib/kubectl_context.sh"

# Ensure we're using the correct kubectl context
ensure_correct_kubectl_context "$(dirname "$0")/.." || exit 1

NAMESPACE="${NAMESPACE:-vault}"

echo -e "${BLUE}=== Configuring Vault Audit Device ===${NC}"
echo ""

# -----------------------------------------------------------------------------
# Check prerequisites
# -----------------------------------------------------------------------------
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check if Vault is initialised
if [ ! -f vault-init.json ]; then
  echo -e "${RED}Error: vault-init.json not found${NC}"
  echo "Run 'task init' first to initialise Vault"
  exit 1
fi

# Check if .env exists
if [ ! -f .env ]; then
  echo -e "${RED}Error: .env file not found${NC}"
  echo "Run 'task init' first to create .env with Vault credentials"
  exit 1
fi

# Source .env to get Vault credentials
source .env

# Check if Vault token is set
if [ -z "${VAULT_TOKEN:-}" ]; then
  echo -e "${RED}Error: VAULT_TOKEN not set in .env${NC}"
  echo "Run 'task init' first to initialise Vault"
  exit 1
fi

# Check if Vault address is set
if [ -z "${VAULT_ADDR:-}" ]; then
  echo -e "${RED}Error: VAULT_ADDR not set in .env${NC}"
  echo "Run 'task init' first to initialise Vault"
  exit 1
fi

# Check if Vault is accessible
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8200/v1/sys/health | grep -q "200\|429"; then
  echo -e "${RED}Error: Cannot connect to Vault at http://localhost:8200${NC}"
  echo "Ensure port forwarding is active: task port-forward"
  exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"
echo ""

# -----------------------------------------------------------------------------
# Ensure audit directory has correct permissions
# -----------------------------------------------------------------------------
echo -e "${BLUE}Checking audit directory permissions...${NC}"

# Get first Vault pod
VAULT_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$VAULT_POD" ]; then
  echo -e "${RED}Error: Could not find Vault pod${NC}"
  exit 1
fi

# Check if data directory is writable (audit logs will be stored here)
if ! kubectl exec -n "$NAMESPACE" "$VAULT_POD" -- test -w /vault/data; then
  echo -e "${RED}Error: /vault/data directory is not writable${NC}"
  echo "This should not happen - check Vault deployment"
  exit 1
fi

echo -e "${GREEN}✓ Audit directory permissions OK${NC}"
echo ""

# -----------------------------------------------------------------------------
# Configure audit device using Terraform
# -----------------------------------------------------------------------------
echo -e "${BLUE}Configuring audit device via Terraform...${NC}"
cd "$(dirname "$0")/../../terraform/vault-audit-devices"

terraform init -upgrade
terraform apply -auto-approve

echo ""
echo -e "${GREEN}✓ Audit device configured successfully${NC}"
echo ""

# -----------------------------------------------------------------------------
# Verify audit device configuration
# -----------------------------------------------------------------------------
echo -e "${BLUE}Verifying audit device...${NC}"

kubectl exec -n "$NAMESPACE" "$VAULT_POD" -- \
  env VAULT_TOKEN="$VAULT_TOKEN" \
  vault audit list

echo ""
echo -e "${GREEN}=== Audit Device Enabled! ===${NC}"
echo ""
echo -e "${BLUE}Configured audit device:${NC}"
echo -e "  • File audit: /vault/data/audit.log"
echo ""
echo -e "${BLUE}View audit logs:${NC}"
echo -e "  kubectl exec -n ${NAMESPACE} ${VAULT_POD:-vault-0} -- cat /vault/data/audit.log"
echo ""
