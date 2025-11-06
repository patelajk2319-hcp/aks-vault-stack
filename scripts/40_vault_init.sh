#!/bin/bash

# =============================================================================
# Initialise Vault
# This script checks if Vault is already initialised, initialises it with a
# single key, and saves credentials to .env and vault-init.json
# =============================================================================

set -euo pipefail

# Source centralised colour configuration
source "$(dirname "$0")/lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"
VAULT_POD="${VAULT_POD:-vault-0}"

# Auto-detect Vault pod name if default doesn't exist
if ! kubectl get pod -n "$NAMESPACE" "$VAULT_POD" &>/dev/null; then
  echo -e "${YELLOW}Pod $VAULT_POD not found, auto-detecting Vault pod...${NC}"
  VAULT_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -z "$VAULT_POD" ]; then
    echo -e "${RED}Error: No Vault pod found in namespace $NAMESPACE${NC}"
    exit 1
  fi
  echo -e "${GREEN}Found Vault pod: $VAULT_POD${NC}"
fi

echo -e "${BLUE}=== Initialising Vault ===${NC}"
echo ""

# Check if Vault is already initialised
STATUS=$(kubectl exec -n "$NAMESPACE" "$VAULT_POD" -- vault status -format=json 2>&1 || echo '{"initialized":false}')
INITIALIZED=$(echo "$STATUS" | grep -o '"initialized":[^,]*' | cut -d':' -f2)

if [ "$INITIALIZED" = "true" ]; then
  echo -e "${YELLOW}Vault is already initialised${NC}"
  echo "Vault details are in vault-init.json and .env"
  echo "If you want to re-initialise, run 'task clean' first"
  exit 1
fi

# Initialise Vault with single key
echo -e "${BLUE}Initialising Vault...${NC}"
kubectl exec -n "$NAMESPACE" "$VAULT_POD" -- \
  vault operator init \
  -key-shares=1 \
  -key-threshold=1 \
  -format=json > vault-init.json

echo ""
echo -e "${GREEN}✓ Vault initialised successfully${NC}"
echo ""
echo -e "${GREEN}Vault Credentials:${NC}"
cat vault-init.json | jq -r '"Root Token: " + .root_token'
cat vault-init.json | jq -r '"Unseal Key: " + .unseal_keys_b64[0]'
echo ""

# Save root token to .env
ROOT_TOKEN=$(cat vault-init.json | jq -r '.root_token')

# Create or update .env file
if [ ! -f .env ]; then
  echo -e "${BLUE}Creating .env file...${NC}"
  cat > .env <<'EOF'
# -----------------------------------------------------------------------------
# Vault Configuration
# -----------------------------------------------------------------------------
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=ROOT_TOKEN_PLACEHOLDER
EOF
  # Replace placeholder with actual token
  sed -i.bak "s|ROOT_TOKEN_PLACEHOLDER|$ROOT_TOKEN|" .env
  rm -f .env.bak
else
  echo -e "${BLUE}Updating .env file...${NC}"
  # Update VAULT_TOKEN in existing .env (with or without export prefix)
  if grep -q "^export VAULT_TOKEN=" .env; then
    sed -i.bak "s|^export VAULT_TOKEN=.*|export VAULT_TOKEN=$ROOT_TOKEN|" .env
  elif grep -q "^VAULT_TOKEN=" .env; then
    sed -i.bak "s|^VAULT_TOKEN=.*|export VAULT_TOKEN=$ROOT_TOKEN|" .env
  else
    echo "export VAULT_TOKEN=$ROOT_TOKEN" >> .env
  fi
  rm -f .env.bak
fi

echo -e "${GREEN}✓ Root token saved to .env${NC}"
echo ""

# Unseal all Vault replicas
echo -e "${BLUE}Unsealing Vault replicas...${NC}"
UNSEAL_KEY=$(cat vault-init.json | jq -r '.unseal_keys_b64[0]')

# Get all Vault pods
VAULT_PODS=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].metadata.name}')

for POD in $VAULT_PODS; do
  echo -e "${BLUE}Unsealing $POD...${NC}"
  kubectl exec -n "$NAMESPACE" "$POD" -- vault operator unseal "$UNSEAL_KEY" >/dev/null
  echo -e "${GREEN}✓ $POD unsealed${NC}"
done

echo ""
echo -e "${GREEN}=== Vault Initialization Complete! ===${NC}"
echo ""
