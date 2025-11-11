#!/bin/bash

# =============================================================================
# Query Vault Audit Logs - Raw JSON Output
# Extracts database credential lifecycle events as raw JSON
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"
OUTPUT_DIR="$(dirname "$0")/../../data"
OUTPUT_FILE="$OUTPUT_DIR/dynamic-raw-json.json"

echo -e "${BLUE}=== Vault Audit Log Query (Raw JSON) ===${NC}"
echo ""

# Create data directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Copy audit log from Vault pod
echo -e "${BLUE}Fetching audit logs...${NC}"
kubectl exec -n "$NAMESPACE" vault-0 -- cat /vault/data/audit.log > /tmp/vault-audit.log 2>/dev/null

# Extract relevant events and output as separate JSON objects
echo -e "${BLUE}Extracting credential lifecycle events in chronological order...${NC}"

# Clear/create output file
: > "$OUTPUT_FILE"

# Process each matching event and append to file
while IFS= read -r line; do
  # Determine event type
  if echo "$line" | jq -e '.request.path | test("database/creds")' > /dev/null 2>&1; then
    event_type="DATABASE CREDENTIAL CREATION"
  elif echo "$line" | jq -e '.request.path | test("sys/leases/renew")' > /dev/null 2>&1; then
    event_type="LEASE RENEWAL"
  elif echo "$line" | jq -e '.request.path | test("sys/leases/revoke")' > /dev/null 2>&1; then
    event_type="LEASE REVOCATION"
  else
    event_type="UNKNOWN EVENT"
  fi

  # Output event header and beautified JSON from audit log
  {
    echo "# ============================================================================================================"
    echo "# $event_type"
    echo "# ============================================================================================================"
    echo ""
    echo "$line" | jq '.'
    echo ""
  } >> "$OUTPUT_FILE"
done < <(cat /tmp/vault-audit.log | \
  jq -c 'select(
    (.request.path | test("database/creds")) or
    (.request.path | test("sys/leases/renew")) or
    (.request.path | test("sys/leases/revoke"))
  ) | select(.type == "response")')

# Remove trailing blank line
sed -i '' '$ d' "$OUTPUT_FILE"

# Clean up
rm -f /tmp/vault-audit.log

# Count events (count event type headers)
event_count=$(grep -cE "^# (DATABASE CREDENTIAL CREATION|LEASE RENEWAL|LEASE REVOCATION)" "$OUTPUT_FILE" || echo 0)

echo -e "${GREEN}Raw JSON data written to: ${OUTPUT_FILE}${NC}"
echo -e "${BLUE}Total events: ${event_count}${NC}"
echo ""
