#!/bin/bash

# =============================================================================
# Query Vault Audit Logs
# Extracts database credential lifecycle events from Vault audit logs
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"
LIMIT="${LIMIT:-10}"

echo -e "${BLUE}=== Vault Audit Log Query (last ${LIMIT} records per section) ===${NC}"
echo ""

# Copy audit log from Vault pod
echo -e "${BLUE}Fetching audit logs...${NC}"
kubectl exec -n "$NAMESPACE" vault-0 -- cat /vault/data/audit.log > /tmp/vault-audit.log 2>/dev/null

# -----------------------------------------------------------------------------
# Database Credential Creation Events
# -----------------------------------------------------------------------------
echo -e "${GREEN}Database Credential Creation Events:${NC}"
echo "------------------------------------"
printf "%-20s | %-20s | %-30s | %s\n" "TIMESTAMP" "SERVICE ACCOUNT" "PATH" "LEASE ID"
printf "%-20s | %-20s | %-30s | %s\n" "--------------------" "--------------------" "------------------------------" "----------------------------------------"

cat /tmp/vault-audit.log | \
  grep 'database/creds' | \
  grep '"type":"response"' | \
  grep '"operation":"read"' | \
  jq -r '[
    .time,
    .auth.display_name,
    .request.path,
    .response.secret.lease_id
  ] | @tsv' | \
  awk -F'\t' '{
    time=$1;
    gsub(/T/, " ", time);
    gsub(/Z/, "", time);
    sub(/\.[0-9]+/, "", time);
    auth=$2;
    gsub(/jwt-wrkld1-system:serviceaccount:vault:/, "", auth);
    path=$3;
    lease=$4;
    printf "%-20s | %-20s | %-30s | %s\n", time, auth, path, lease
  }' | \
  tail -n "$LIMIT"

echo ""

# -----------------------------------------------------------------------------
# Lease Renewal Events
# -----------------------------------------------------------------------------
echo -e "${GREEN}Credential Lease Renewal Events:${NC}"
echo "--------------------------------"

if grep -q 'sys/leases/renew' /tmp/vault-audit.log; then
  printf "%-20s | %-20s | %s\n" "TIMESTAMP" "SERVICE ACCOUNT" "LEASE ID"
  printf "%-20s | %-20s | %s\n" "--------------------" "--------------------" "------------------------------------------------------------"

  cat /tmp/vault-audit.log | \
    grep 'sys/leases/renew' | \
    grep '"type":"response"' | \
    jq -r '[
      .time,
      .auth.display_name,
      .request.data.lease_id // "N/A"
    ] | @tsv' | \
    awk -F'\t' '{
      time=$1;
      gsub(/T/, " ", time);
      gsub(/Z/, "", time);
      sub(/\.[0-9]+/, "", time);
      auth=$2;
      gsub(/jwt-wrkld1-system:serviceaccount:vault:/, "", auth);
      lease=$3;
      printf "%-20s | %-20s | %s\n", time, auth, lease
    }' | \
    tail -n "$LIMIT"
else
  echo "No renewal events found yet"
fi

echo ""

# -----------------------------------------------------------------------------
# Lease Revocation Events
# -----------------------------------------------------------------------------
echo -e "${GREEN}Credential Lease Revocation Events:${NC}"
echo "-----------------------------------"

if grep -q '"path":"sys/leases/revoke' /tmp/vault-audit.log; then
  printf "%-20s | %-20s | %s\n" "TIMESTAMP" "SERVICE ACCOUNT" "REVOKED LEASE ID"
  printf "%-20s | %-20s | %s\n" "--------------------" "--------------------" "----------------------------------------------------------------"

  cat /tmp/vault-audit.log | \
    grep '"path":"sys/leases/revoke' | \
    grep '"type":"response"' | \
    jq -r '[
      .time,
      .auth.display_name,
      (.request.path | sub("sys/leases/revoke/"; ""))
    ] | @tsv' | \
    awk -F'\t' '{
      time=$1;
      gsub(/T/, " ", time);
      gsub(/Z/, "", time);
      sub(/\.[0-9]+/, "", time);
      auth=$2;
      lease=$3;
      printf "%-20s | %-20s | %s\n", time, auth, lease
    }' | \
    tail -n "$LIMIT"
else
  echo "No revocation events found yet"
fi

echo ""

# Clean up
rm -f /tmp/vault-audit.log
