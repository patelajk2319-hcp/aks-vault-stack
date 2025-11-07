#!/bin/bash

# =============================================================================
# Display Dynamic PostgreSQL Credentials for Workload 1
# Reads credentials from Kubernetes secret synced by VSO
# =============================================================================

set -euo pipefail

# Source centralised colour configuration
source "$(dirname "$0")/../lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"
SECRET_NAME="postgres-dynamic-creds-wrkld1"
VDS_NAME="postgres-dynamic-creds-wrkld1"

echo -e "${BLUE}=== Dynamic PostgreSQL Credentials ===${NC}"
echo ""
echo -e "${BLUE}Time Run:${NC}"
echo "---------"
echo "$(date '+%d %b %Y - %H:%M:%S')"
echo ""

# -----------------------------------------------------------------------------
# Check if secret exists
# -----------------------------------------------------------------------------
if ! kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &>/dev/null; then
  echo -e "${RED}Error: Secret '$SECRET_NAME' not found in namespace '$NAMESPACE'${NC}"
  echo ""
  echo "This secret is created by Vault Secrets Operator (VSO) after running:"
  echo "  task database    # Configure Vault database secrets engine"
  echo "  task workload1   # Deploy workload with VSO"
  echo ""
  echo "Make sure you have completed the full deployment workflow:"
  echo "  1. task infra    - Deploy AKS infrastructure"
  echo "  2. task vault    - Deploy Vault to AKS"
  echo "  3. task init     - Initialise Vault"
  echo "  4. task vso      - Deploy Vault Secrets Operator"
  echo "  5. task database - Configure PostgreSQL in Vault"
  echo "  6. task workload1 - Deploy workload 1"
  exit 1
fi

# -----------------------------------------------------------------------------
# Read credentials from secret
# -----------------------------------------------------------------------------
echo -e "${BLUE}Reading credentials from Kubernetes secret...${NC}"

USERNAME=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.username}' | base64 -d)
PASSWORD=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.password}' | base64 -d)

# Get PostgreSQL connection details from terraform
cd "$(dirname "$0")/../../terraform/core-infra"
POSTGRES_SERVER_FQDN=$(terraform output -raw postgres_server_fqdn)
POSTGRES_DATABASE=$(terraform output -raw postgres_database_name)

echo -e "${GREEN}✓ Credentials retrieved${NC}"
echo ""

# -----------------------------------------------------------------------------
# Display credentials
# -----------------------------------------------------------------------------
echo -e "${BLUE}Connection Details:${NC}"
echo "  Host:     ${POSTGRES_SERVER_FQDN}"
echo "  Port:     5432"
echo "  Database: ${POSTGRES_DATABASE}"
echo "  Username: ${USERNAME}"
echo "  Password: ${PASSWORD}"
echo ""

echo -e "${BLUE}Connection String:${NC}"
echo "  postgresql://${USERNAME}:${PASSWORD}@${POSTGRES_SERVER_FQDN}:5432/${POSTGRES_DATABASE}?sslmode=require"
echo ""

# -----------------------------------------------------------------------------
# Display secret metadata
# -----------------------------------------------------------------------------
echo -e "${BLUE}Credential Metadata:${NC}"

CREATION_TIME=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.creationTimestamp}')

# Get last renewal time from VaultDynamicSecret status (Unix timestamp)
LAST_RENEWAL_TIMESTAMP=$(kubectl get vaultdynamicsecret "$VDS_NAME" -n "$NAMESPACE" -o jsonpath='{.status.lastRenewalTime}' 2>/dev/null)

if [ -n "$LAST_RENEWAL_TIMESTAMP" ]; then
  # Convert Unix timestamp to human-readable format
  LAST_REFRESH=$(date -r "$LAST_RENEWAL_TIMESTAMP" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || echo "N/A")
else
  LAST_REFRESH="N/A"
fi

echo "  Created: ${CREATION_TIME}"
echo "  Last Refresh: ${LAST_REFRESH}"
echo ""

echo -e "${YELLOW}Note: Credentials are dynamically generated and rotate every 5 minutes${NC}"
echo ""
