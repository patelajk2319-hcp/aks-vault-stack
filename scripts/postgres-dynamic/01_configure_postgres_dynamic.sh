#!/bin/bash

# =============================================================================
# Configure Vault for Dynamic PostgreSQL Credentials
# Sets up JWT auth and PostgreSQL secrets engine
# =============================================================================

set -e

# Source centralised colour configuration
source "$(dirname "$0")/../lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"

echo -e "${BLUE}=== Configuring Vault for Dynamic PostgreSQL Credentials ===${NC}"
echo ""

# -----------------------------------------------------------------------------
# Check prerequisites
# -----------------------------------------------------------------------------
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check if Vault is initialised
if [ ! -f vault-init.json ]; then
  echo -e "${RED}Error: vault-init.json not found${NC}"
  echo "Run 'task init' first to initialise Vault"
  exit 1
fi

# Check if .env exists
if [ ! -f .env ]; then
  echo -e "${RED}Error: .env file not found${NC}"
  echo "Run 'task init' first to create .env with Vault credentials"
  exit 1
fi

# Source .env to get Vault credentials
source .env

# Check if Vault is accessible
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8200/v1/sys/health | grep -q "200\|429"; then
  echo -e "${RED}Error: Cannot connect to Vault at http://localhost:8200${NC}"
  echo "Ensure port forwarding is active: task port-forward"
  exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"
echo ""

# -----------------------------------------------------------------------------
# Validate infrastructure variables from .env
# -----------------------------------------------------------------------------
echo -e "${BLUE}Validating infrastructure configuration...${NC}"

# Check required infrastructure variables
if [ -z "$AKS_OIDC_ISSUER_URL" ] || [ -z "$POSTGRES_SERVER_FQDN" ] || \
   [ -z "$POSTGRES_DATABASE" ] || [ -z "$POSTGRES_ADMIN_USER" ]; then
  echo -e "${RED}Error: Required infrastructure variables not found in .env${NC}"
  echo "Please run 'task infra' first to deploy infrastructure and populate .env"
  exit 1
fi

echo -e "${GREEN}✓ Infrastructure configuration validated${NC}"
echo ""

# -----------------------------------------------------------------------------
# Build PostgreSQL connection URL
# -----------------------------------------------------------------------------
echo -e "${BLUE}Building PostgreSQL connection string...${NC}"

if [ -z "$POSTGRES_ADMIN_PASSWORD" ]; then
  echo -e "${RED}Error: POSTGRES_ADMIN_PASSWORD not set in .env${NC}"
  exit 1
fi

POSTGRES_CONNECTION_URL="postgresql://${POSTGRES_ADMIN_USER}:${POSTGRES_ADMIN_PASSWORD}@${POSTGRES_SERVER_FQDN}:5432/${POSTGRES_DATABASE}?sslmode=require"

echo -e "${GREEN}✓ Connection string built${NC}"
echo ""

# -----------------------------------------------------------------------------
# Configure Vault using Terraform
# -----------------------------------------------------------------------------
echo -e "${BLUE}Configuring Vault JWT auth and secrets engines...${NC}"
cd "$(dirname "$0")/../../terraform/postgres-dynamic"

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
# Vault Configuration
namespace           = "$NAMESPACE"
oidc_issuer_url     = "$AKS_OIDC_ISSUER_URL"
postgres_connection_url = "$POSTGRES_CONNECTION_URL"
EOF

# Initialise Terraform
terraform init -upgrade

# Apply Terraform configuration
echo -e "${BLUE}Applying Terraform configuration...${NC}"
terraform apply -auto-approve > /dev/null 2>&1 || {
  echo -e "${RED}Error: Terraform apply failed${NC}"
  terraform apply -auto-approve
  exit 1
}

echo ""
echo -e "${GREEN}✓ Vault configured successfully${NC}"
echo ""
echo -e "${GREEN}=== Dynamic Secrets Enabled! ===${NC}"
echo ""
