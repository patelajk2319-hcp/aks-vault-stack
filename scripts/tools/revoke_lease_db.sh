#!/bin/bash

# =============================================================================
# Revoke Vault Database Credential Lease
# Revokes a specific database credential lease in Vault
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"
LEASE_PATH="${1:-}"

# Validate lease path provided
if [ -z "$LEASE_PATH" ]; then
  echo -e "${RED}Error: Lease path required${NC}"
  echo "Usage: $0 <lease_path>"
  echo "Example: $0 database/creds/postgres-role/abc123xyz"
  exit 1
fi

# Check prerequisites
if [ ! -f .env ]; then
  echo -e "${RED}Error: .env file not found${NC}"
  echo "Run 'task init' first to create .env with Vault credentials"
  exit 1
fi

source .env

# Check Vault token
if [ -z "${VAULT_TOKEN:-}" ]; then
  echo -e "${RED}Error: VAULT_TOKEN not set in .env${NC}"
  exit 1
fi

# Check Vault address
if [ -z "${VAULT_ADDR:-}" ]; then
  echo -e "${RED}Error: VAULT_ADDR not set in .env${NC}"
  exit 1
fi

# Check Vault connectivity
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8200/v1/sys/health | grep -q "200\|429"; then
  echo -e "${RED}Error: Cannot connect to Vault at http://localhost:8200${NC}"
  echo "Ensure port forwarding is active: task port-forward"
  exit 1
fi

echo -e "${BLUE}=== Revoking Database Credential Lease ===${NC}"
echo ""
echo -e "${BLUE}Lease path:${NC} $LEASE_PATH"
echo ""

# Revoke the lease
vault lease revoke "$LEASE_PATH"

echo ""
echo -e "${GREEN}✓ Lease revoked successfully${NC}"
echo ""
echo -e "${BLUE}Verify revocation in audit logs:${NC}"
echo "  task audit-logs limit=5"
echo ""
