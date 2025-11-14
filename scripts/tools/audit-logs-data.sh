#!/bin/bash

# =============================================================================
# Export Main Vault Audit Logs as Raw JSON
# Exports all audit log entries from the main audit device
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"
OUTPUT_DIR="$(dirname "$0")/../../data"
OUTPUT_FILE="$OUTPUT_DIR/audit-logs.json"

echo -e "${BLUE}=== Main Vault Audit Log Export ===${NC}"
echo ""

# Create data directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Copy audit log from Vault pod
echo -e "${BLUE}Fetching main audit logs...${NC}"
kubectl exec -n "$NAMESPACE" vault-0 -- cat /vault/data/audit.log > /tmp/vault-audit.log 2>/dev/null

# Copy all audit log entries to output file as JSON array
echo -e "${BLUE}Exporting audit log entries...${NC}"

# Create JSON array with all entries
jq -s '.' /tmp/vault-audit.log > "$OUTPUT_FILE"

# Count total entries
entry_count=$(cat /tmp/vault-audit.log | wc -l | tr -d ' ')

# Clean up
rm -f /tmp/vault-audit.log

echo -e "${GREEN}Audit log data written to: ${OUTPUT_FILE}${NC}"
echo -e "${BLUE}Total entries: ${entry_count}${NC}"
echo ""
