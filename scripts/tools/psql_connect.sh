#!/bin/bash

# =============================================================================
# Connect to PostgreSQL Database
# =============================================================================
#
# IMPORTANT: If this task hangs or times out when connecting, you need to add
# your client IP address to the Azure PostgreSQL firewall rules:
#
# 1. Go to Azure Portal
# 2. Navigate to your PostgreSQL Flexible Server
# 3. Go to Networking section
# 4. Add your current public IP address to the firewall rules
# 5. Save the changes and retry the connection
# =============================================================================

set -e

# Source centralised colour configuration
source "$(dirname "$0")/../lib/colors.sh"

USERNAME="$1"
PASSWORD="$2"

# Validate parameters
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
  echo -e "${RED}Error: username and password parameters are required${NC}"
  echo "Usage: task psql username=<user> password=<pass>"
  exit 1
fi

source .env

# Validate required environment variables
if [ -z "$POSTGRES_SERVER_FQDN" ] || [ -z "$POSTGRES_DATABASE" ]; then
  echo -e "${RED}Error: POSTGRES_SERVER_FQDN and POSTGRES_DATABASE not found in .env${NC}"
  echo "Please run 'task infra' first to deploy infrastructure"
  exit 1
fi

# Display connection information
echo -e "${BLUE}Connecting to PostgreSQL...${NC}"
echo "  Server: $POSTGRES_SERVER_FQDN"
echo "  Database: $POSTGRES_DATABASE"
echo "  User: $USERNAME"
echo ""

# Connect to PostgreSQL
export PGPASSWORD="$PASSWORD"
psql -h "$POSTGRES_SERVER_FQDN" -U "$USERNAME" -d "$POSTGRES_DATABASE" -c "\conninfo"
