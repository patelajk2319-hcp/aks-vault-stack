#!/bin/bash

# Deploy Workload 1 - PostgreSQL Database and JWT Authentication

set -euo pipefail

source "$(dirname "$0")/../lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"

echo -e "${BLUE}=== Deploying Workload 1 - PostgreSQL and JWT Auth ===${NC}"
echo ""

echo -e "${BLUE}Checking prerequisites...${NC}"
if [ ! -f vault-init.json ]; then
  echo -e "${RED}Error: vault-init.json not found${NC}"
  echo "Run 'task init' first to initialise Vault"
  exit 1
fi
if [ ! -f .env ]; then
  echo -e "${RED}Error: .env file not found${NC}"
  echo "Run 'task init' first to create .env with Vault credentials"
  exit 1
fi

source .env
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8200/v1/sys/health | grep -q "200\|429"; then
  echo -e "${RED}Error: Cannot connect to Vault at http://localhost:8200${NC}"
  echo "Ensure port forwarding is active: task port-forward"
  exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"
echo ""

echo -e "${BLUE}Validating infrastructure configuration...${NC}"
if [ -z "$AKS_OIDC_ISSUER_URL" ]; then
  echo -e "${RED}Error: AKS_OIDC_ISSUER_URL not found in .env${NC}"
  echo "Please run 'task infra' first to deploy infrastructure and populate .env"
  exit 1
fi

if [ -z "$POSTGRES_CONNECTION_URL" ]; then
  # Construct connection URL from individual components
  if [ -z "$POSTGRES_ADMIN_PASSWORD" ] || [ -z "$POSTGRES_ADMIN_USER" ] || [ -z "$POSTGRES_SERVER_FQDN" ] || [ -z "$POSTGRES_DATABASE" ]; then
    echo -e "${RED}Error: Required PostgreSQL variables not found in .env${NC}"
    echo "Please ensure these variables are set in .env:"
    echo "  - POSTGRES_ADMIN_PASSWORD"
    echo "  - POSTGRES_ADMIN_USER"
    echo "  - POSTGRES_SERVER_FQDN"
    echo "  - POSTGRES_DATABASE"
    exit 1
  fi
  POSTGRES_CONNECTION_URL="postgresql://${POSTGRES_ADMIN_USER}:${POSTGRES_ADMIN_PASSWORD}@${POSTGRES_SERVER_FQDN}:5432/${POSTGRES_DATABASE}?sslmode=require"
fi

echo -e "${GREEN}✓ Infrastructure configuration validated${NC}"
echo ""

echo -e "${BLUE}Deploying workload 1 (PostgreSQL + JWT auth + VSO)...${NC}"
cd "$(dirname "$0")/../../terraform/workload-1"
cat > terraform.tfvars <<EOF
# Workload 1 Configuration
namespace              = "$NAMESPACE"
oidc_issuer_url        = "$AKS_OIDC_ISSUER_URL"
postgres_connection_url = "$POSTGRES_CONNECTION_URL"
EOF

terraform init -upgrade
echo -e "${BLUE}Applying Terraform configuration...${NC}"
terraform apply -auto-approve > /dev/null 2>&1 || {
  echo -e "${RED}Error: Terraform apply failed${NC}"
  terraform apply -auto-approve
  exit 1
}

echo ""
echo -e "${GREEN}✓ Workload 1 deployed successfully${NC}"
echo ""
echo -e "${GREEN}=== Workload 1 Ready ===${NC}"
echo ""
echo -e "${BLUE}Database secrets engine:${NC} database/"
echo -e "${BLUE}JWT auth path:${NC}          jwt/wrkld1"
echo -e "${BLUE}Service account:${NC}        wrkld1-svc-acc"
echo -e "${BLUE}K8s secret:${NC}             postgres-dynamic-creds-wrkld1"
echo ""
