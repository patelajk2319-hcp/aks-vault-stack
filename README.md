# AKS Vault Stack with JWT Authentication

Deploy HashiCorp Vault Enterprise on Azure AKS with PostgreSQL dynamic credentials using JWT authentication.

## Prerequisites

### Azure Requirements
- Active Azure subscription
- Azure CLI authenticated
- Contributor access to the subscription

### Required Tools (install via Homebrew)
```bash
brew install terraform
brew install azure-cli
brew install kubectl
brew install jq
brew install go-task
brew install postgresql
```

### Vault Enterprise Licence
Place your Vault Enterprise licence file at:
```
licenses/vault-enterprise/license.lic
```

## Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd aks-vault-stack-jwt
```

### 2. Create `.env` File
Create a `.env` file in the root directory with the following variables:

```bash
# -----------------------------------------------------------------------------
# Vault Configuration
# -----------------------------------------------------------------------------
export VAULT_ADDR=http://localhost:8200

# -----------------------------------------------------------------------------
# Azure Provider Configuration
# -----------------------------------------------------------------------------
export ARM_SUBSCRIPTION_ID=<your-subscription-id>
export ARM_TENANT_ID=<your-tenant-id>

# -----------------------------------------------------------------------------
# PostgreSQL Configuration
# -----------------------------------------------------------------------------
export POSTGRES_ADMIN_PASSWORD=<your-secure-password>
```

### 3. Deploy the Stack
```bash
# Authenticate to Azure
task login

# Deploy infrastructure (AKS + PostgreSQL)
task infra

# Deploy Vault to AKS
task vault

# Initialise Vault and set up port forwarding
task init

# Deploy Vault Secrets Operator
task vso

# Configure dynamic PostgreSQL credentials
task dynamic

# Display connection information
task info
```

## Testing Dynamic Credentials

Connect to PostgreSQL using dynamically generated credentials:
```bash
task psql username=<username> password=<password>
```

Use `task info` to retrieve the current dynamic credentials from Kubernetes secrets.

## Cleanup

```bash
# Remove Vault and VSO (keeps AKS running)
task rm

# Destroy all infrastructure including AKS
task nuke
```

## Available Commands

Run `task --list` to see all available commands.

## Architecture

- **AKS Cluster**: Kubernetes cluster in Azure (UK South region)
- **Vault Enterprise**: HA deployment with integrated storage
- **PostgreSQL**: Azure Flexible Server with dynamic credential generation
- **VSO**: Vault Secrets Operator for Kubernetes-native secret injection
- **JWT Auth**: Workload identity using AKS OIDC issuer

## Notes

- Dynamic credentials rotate every 5 minutes
- Vault root token and unseal key are stored in `vault-init.json` (gitignored)
- All sensitive data is stored in `.env` (gitignored)
