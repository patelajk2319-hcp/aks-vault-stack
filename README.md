# AKS Vault Stack

Deploy HashiCorp Vault Enterprise on Azure AKS with PostgreSQL dynamic credentials.

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
git clone https://github.com/patelajk2319-hcp/aks-vault-stack.git
cd aks-vault-stack
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

# Unseal Vault
task unseal

# Enable Audit Logs
task audit

# Deploy Vault Secrets Operator
task vso

# Deploy Workload
task wkd

# Display connection information
task info
```

## Testing Dynamic Credentials

Connect to PostgreSQL using dynamically generated credentials:
```bash
task psql username=<username> password=<password>
```

Use `task info` to retrieve the current dynamic credentials from Kubernetes secrets.

**⚠️ IMPORTANT:** If the `task psql` command hangs or times out, you must add your client IP address to the Azure PostgreSQL firewall rules:

1. Go to the Azure Portal
2. Navigate to your PostgreSQL Flexible Server
3. Select **Networking** from the left menu
4. Add your current public IP address to the firewall rules
5. Save the changes and retry the connection

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

## Troubleshooting

### PostgreSQL Connection Hangs or Times Out

If you experience connection issues when running `task psql`, this is typically due to Azure PostgreSQL firewall restrictions.

**Solution:**
1. Navigate to the Azure Portal
2. Find your PostgreSQL Flexible Server (resource group: `rg-aks-vault-stack`)
3. Go to **Networking** in the left-hand menu
4. Under **Firewall rules**, click **Add current client IP address**
5. Alternatively, manually add your public IP address with a rule name
6. Click **Save** and wait for the changes to apply
7. Retry the `task psql` command

**Note:** Your public IP address may change if you're on a dynamic IP connection. You may need to update the firewall rule accordingly.

## Notes

- Dynamic credentials rotate every 5 minutes
- Vault root token and unseal key are stored in `vault-init.json` (gitignored)
- All sensitive data is stored in `.env` (gitignored)
