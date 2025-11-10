#!/bin/bash

# =============================================================================
# Unseal Vault
# Unseals all Vault replicas using unseal key from vault-init.json
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"

echo -e "${BLUE}=== Unsealing Vault ===${NC}"
echo ""

if [ ! -f vault-init.json ]; then
  echo -e "${RED}Error: vault-init.json not found${NC}"
  echo "Run 'task init' first to initialise Vault"
  exit 1
fi

echo -e "${BLUE}Found vault-init.json${NC}"
echo ""

UNSEAL_KEY=$(cat vault-init.json | jq -r '.unseal_keys_b64[0]')

VAULT_PODS=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].metadata.name}')

if [ -z "$VAULT_PODS" ]; then
  echo -e "${RED}Error: No Vault pods found in namespace $NAMESPACE${NC}"
  exit 1
fi

for POD in $VAULT_PODS; do
  echo -e "${BLUE}Checking seal status of $POD...${NC}"

  SEALED=$(kubectl exec -n "$NAMESPACE" "$POD" -- vault status -format=json 2>/dev/null | jq -r '.sealed' || echo "true")

  if [ "$SEALED" = "true" ]; then
    echo -e "${BLUE}Unsealing $POD...${NC}"
    kubectl exec -n "$NAMESPACE" "$POD" -- vault operator unseal "$UNSEAL_KEY" >/dev/null
    echo -e "${GREEN}✓ $POD unsealed${NC}"
  else
    echo -e "${GREEN}✓ $POD already unsealed${NC}"
  fi
done

echo ""
echo -e "${GREEN}=== All Vault replicas unsealed! ===${NC}"
echo ""
