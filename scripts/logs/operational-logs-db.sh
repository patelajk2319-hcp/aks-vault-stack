#!/bin/bash

# =============================================================================
# Query Vault Operational Logs for Database Operations
# Filters operational logs for database credential lifecycle events
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"
LINES="${LINES:-100}"

echo -e "${BLUE}=== Vault Operational Logs - Database Operations ===${NC}"
echo ""

# Get Vault pod
VAULT_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$VAULT_POD" ]; then
  echo -e "${RED}Error: Could not find Vault pod${NC}"
  exit 1
fi

echo -e "${BLUE}Fetching operational logs from ${VAULT_POD}...${NC}"
echo -e "${BLUE}Filtering for database-related operations (last ${LINES} lines)${NC}"
echo ""

# Filter operational logs for database-related entries
# Looking for:
# - secrets.database - database secrets engine operations
# - database/creds - credential generation
# - database/roles - role operations
# - lease renewal/revocation related to database
kubectl logs -n "$NAMESPACE" "$VAULT_POD" --tail="$LINES" 2>&1 | \
  grep -E "(secrets\.database|database/creds|database/roles|database/config|rotation)" || \
  echo -e "${YELLOW}No database-related operational log entries found in the last ${LINES} lines${NC}"

echo ""
echo -e "${GREEN}=== End of Database Operational Logs ===${NC}"
