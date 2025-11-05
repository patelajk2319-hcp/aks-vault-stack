#!/bin/bash

# =============================================================================
# Port Forwarding for Vault
# Sets up port forwarding to access Vault UI locally
# =============================================================================

set -e

# Source centralised colour configuration
source "$(dirname "$0")/lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"

# Stop any existing port-forwards for Vault
pkill -f "port-forward.*vault.*8200" 2>/dev/null || true

echo -e "${BLUE}Setting up port-forward to Vault...${NC}"

# Port forward to Vault service
nohup kubectl port-forward -n "$NAMESPACE" svc/vault 8200:8200 > /dev/null 2>&1 &

sleep 2
echo -e "${GREEN}✓ Port-forward active${NC}"
echo ""
echo -e "${YELLOW}Vault UI accessible at:${NC} ${BLUE}http://localhost:8200/ui${NC}"
echo ""
echo -e "${YELLOW}To stop port forwarding:${NC}"
echo -e "  pkill -f 'port-forward.*vault'"
echo ""
