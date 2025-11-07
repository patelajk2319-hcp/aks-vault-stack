#!/bin/bash

# =============================================================================
# Configure JWT Authentication and VSO for Workload 1
# Sets up JWT auth, ServiceAccount, and VSO manifests for database access
# Requires postgres-dynamic to be configured first
# =============================================================================

set -euo pipefail

# Source centralised colour configuration
source "$(dirname "$0")/../lib/colors.sh"

NAMESPACE="${NAMESPACE:-vault}"

echo -e "${BLUE}=== Configuring JWT Authentication and VSO for Workload 1 ===${NC}"
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

# Check if postgres-dynamic has been configured
if ! vault secrets list | grep -q "database/"; then
  echo -e "${RED}Error: PostgreSQL database secrets engine not configured${NC}"
  echo "Please run 'task dynamic' first to configure the database backend"
  exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"
echo ""

# -----------------------------------------------------------------------------
# Get database configuration from postgres-dynamic
# -----------------------------------------------------------------------------
echo -e "${BLUE}Retrieving database configuration from postgres-dynamic...${NC}"

POSTGRES_DYNAMIC_DIR="$(dirname "$0")/../../terraform/postgres-dynamic"
if [ ! -f "$POSTGRES_DYNAMIC_DIR/terraform.tfstate" ]; then
  echo -e "${RED}Error: postgres-dynamic terraform state not found${NC}"
  echo "Please run 'task dynamic' first"
  exit 1
fi

cd "$POSTGRES_DYNAMIC_DIR"
DATABASE_MOUNT_PATH=$(terraform output -raw database_mount_path 2>/dev/null || echo "database")
DATABASE_ROLE_NAME=$(terraform output -raw database_role_name 2>/dev/null || echo "postgres-role")
CREDENTIAL_TTL_SECONDS=$(terraform output -raw credential_ttl_seconds 2>/dev/null || echo "300")

echo -e "${GREEN}✓ Database configuration retrieved${NC}"
echo -e "  Database mount: ${DATABASE_MOUNT_PATH}"
echo -e "  Database role: ${DATABASE_ROLE_NAME}"
echo -e "  Credential TTL: ${CREDENTIAL_TTL_SECONDS}s"
echo ""

# -----------------------------------------------------------------------------
# Validate infrastructure variables from .env
# -----------------------------------------------------------------------------
echo -e "${BLUE}Validating infrastructure configuration...${NC}"

# Check required infrastructure variables
if [ -z "$AKS_OIDC_ISSUER_URL" ]; then
  echo -e "${RED}Error: AKS_OIDC_ISSUER_URL not found in .env${NC}"
  echo "Please run 'task infra' first to deploy infrastructure and populate .env"
  exit 1
fi

echo -e "${GREEN}✓ Infrastructure configuration validated${NC}"
echo ""

# -----------------------------------------------------------------------------
# Configure JWT auth and VSO using Terraform
# -----------------------------------------------------------------------------
echo -e "${BLUE}Configuring JWT authentication and VSO...${NC}"
cd "$(dirname "$0")/../../terraform/auth-jwt-wrkld-1"

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
# JWT Auth and Workload Configuration
namespace              = "$NAMESPACE"
oidc_issuer_url        = "$AKS_OIDC_ISSUER_URL"
database_mount_path    = "$DATABASE_MOUNT_PATH"
database_role_name     = "$DATABASE_ROLE_NAME"
credential_ttl_seconds = $CREDENTIAL_TTL_SECONDS
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
echo -e "${GREEN}✓ JWT authentication and VSO configured successfully${NC}"
echo ""
echo -e "${GREEN}=== Workload 1 Ready for Dynamic Credentials! ===${NC}"
echo ""
