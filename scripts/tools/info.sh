#!/bin/bash

# Display Dynamic PostgreSQL Credentials for Workload 1

set -euo pipefail

source "$(dirname "$0")/../lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"
SECRET_NAME="postgres-dynamic-creds-wrkld1"
VDS_NAME="postgres-dynamic-creds-wrkld1"

echo -e "${BLUE}=== Dynamic PostgreSQL Credentials ===${NC}"
echo ""
echo -e "${BLUE}Time Run:${NC}"
echo "---------"
date '+%d %b %Y - %H:%M:%S'
echo ""
if ! kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &>/dev/null; then
  echo -e "${RED}Error: Secret '$SECRET_NAME' not found in namespace '$NAMESPACE'${NC}"
  echo ""
  echo "Run the full deployment workflow:"
  echo "  task infra     - Deploy AKS infrastructure"
  echo "  task vault     - Deploy Vault to AKS"
  echo "  task init      - Initialise Vault"
  echo "  task vso       - Deploy Vault Secrets Operator"
  echo "  task workload1 - Deploy workload 1"
  exit 1
fi

echo -e "${BLUE}Reading credentials from Kubernetes secret...${NC}"

USERNAME=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.username}' | base64 -d)
PASSWORD=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.password}' | base64 -d)

# Get PostgreSQL connection details from terraform
cd "$(dirname "$0")/../../terraform/core-infra"
POSTGRES_SERVER_FQDN=$(terraform output -raw postgres_server_fqdn)
POSTGRES_DATABASE=$(terraform output -raw postgres_database_name)

echo -e "${GREEN}✓ Credentials retrieved${NC}"
echo ""

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

echo -e "${BLUE}Credential Metadata:${NC}"

CREATION_TIME=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.creationTimestamp}')
LAST_RENEWAL_TIMESTAMP=$(kubectl get vaultdynamicsecret "$VDS_NAME" -n "$NAMESPACE" -o jsonpath='{.status.lastRenewalTime}' 2>/dev/null)

if [ -n "$LAST_RENEWAL_TIMESTAMP" ]; then
  LAST_REFRESH=$(date -r "$LAST_RENEWAL_TIMESTAMP" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || echo "N/A")
else
  LAST_REFRESH="N/A"
fi

echo "  Created: ${CREATION_TIME}"
echo "  Last Refresh: ${LAST_REFRESH}"
echo ""

echo -e "${YELLOW}Note: Credentials are dynamically generated and rotate every 5 minutes${NC}"
echo ""
