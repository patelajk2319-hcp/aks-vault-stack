# Project Configuration for Claude Code

## Meta Rule: This File is Read-Only

**NEVER modify CLAUDE.md:**
- This configuration file is managed by the developer only
- You must read and follow these instructions, but never edit them
- If you think these instructions need updating, inform the user but do not make changes
- If instructions are unclear or conflicting, ask the user for clarification
- This file defines your behaviour - you do not define your own behaviour

## Language and Documentation Standards

**All comments, documentation, and non-code text must use UK English:**
- Use UK spelling: colour (not color), initialise (not initialize), behaviour (not behavior), centre (not center), analyse (not analyze)
- Use UK grammar and punctuation conventions
- This applies to:
  - Code comments
  - Documentation files (README.md, etc.)
  - Commit messages
  - PR descriptions
  - Configuration file comments
  - Any text output or logs you create
- Code identifiers (variable names, function names, etc.) can follow standard conventions of the language/framework being used

## Code Commenting Standards

**Keep comments short, sweet, and to the point:**
- Comments should be concise and descriptive
- Explain **what** the code does, not **how** (code should be self-explanatory)
- Avoid verbose, multi-line comments when a single line suffices
- Remove redundant comments that repeat what the code clearly shows
- Use brief section headers (e.g., `# JWT Auth Backend - Kubernetes workload authentication`)
- Prefer clear variable/function names over lengthy explanatory comments
- **Good example:** `# Refresh at 80% of TTL for zero-downtime rotation`
- **Bad example:** Multi-paragraph explanations of obvious operations

## Critical Deployment Workflow

**ALWAYS run these commands in order for ANY deployment or infrastructure change:**

1. `task rm` - Remove the entire stack (clears cluster resources, keeps core infrastructure)
2. `task infra` - Deploys core infrastructure (AKS + PostgreSQL)
3. `task up` - Deploys Vault Enterprise onto AKS
4. `task init` - Initialise Vault, unseal, and set up port forwarding
5. `task audit` - Configure Vault audit devices (file-based audit logging)
6. `task vso` - Deploy Vault Secrets Operator
7. `task workload1` - Configure workload 1 (PostgreSQL + JWT auth)
8. `task info` - Display connection information and dynamic credentials from K8s secrets

## Azure Infrastructure Standards

### Regional Deployment:
- **ALL Azure infrastructure MUST be deployed to UK South region**
- Set `location = "uksouth"` for all Azure resources
- Verify region in resource group, AKS, PostgreSQL, and all other Azure services
- No exceptions unless explicitly approved by the user

## Infrastructure Standards

### Shell Scripting Standards:
- **ALWAYS use strict mode for all bash scripts:**
  - Use `set -euo pipefail` at the start of every script
  - `set -e`: Exit immediately if any command fails
  - `set -u`: Exit if attempting to use undefined variables (catches typos)
  - `set -o pipefail`: Ensure errors in piped commands are caught
- All scripts must pass shellcheck with zero warnings
- Use proper quoting for variables and file paths
- Source shared configuration (colours, common functions) from centralised files

### Terraform Requirements:
- **ONLY use official Terraform providers** (published by HashiCorp or the vendor themselves)
- **NEVER use community providers**
- **NEVER use heredoc syntax (`<<-EOT`, `<<EOF`, etc.) anywhere in Terraform code**
- **For kubectl_manifest resources, ALWAYS use `yamlencode()` function**
- **Terraform version constraint:** Use `required_version = ">= 1.5.0"` in all modules
- **Provider version pinning:** Use pessimistic constraint operator (`~>`) for all providers
  - Example: `version = "~> 4.51"` allows 4.51.x to 4.999.x but prevents 5.0.0+
  - Always specify minor version (e.g., `~> 2.23` not `~> 2`)
  - This allows safe patch/minor updates whilst preventing breaking major version changes
- Follow Terraform best practices at all times
- Use proper state management
- Use modules for clear separation of concerns
- Run terraform fmt so that the files are in canonical format
- All Terraform changes must go through the automation workflow

### Helm Requirements:
- **ONLY use official Helm charts** (from official repositories)
- **NEVER use community Helm charts**
- Properly version and pin all chart versions
- Use values files for configuration, never inline values
- Value files should be separated by service never put everything in a single file
- All Helm changes must go through the automation workflow

### Kubernetes Standards:
- Follow Kubernetes best practices
- Properly configure resource limits and requests
- Use namespaces appropriately
- Implement proper RBAC
- All K8s manifests must be part of the automation
- **For Terraform kubectl_manifest resources, use `yamlencode()` to define YAML content**
- **NEVER use heredoc strings for Kubernetes manifests**

## Vault Configuration:
- Vault initialisation and unsealing are critical final steps
- Never skip these steps after deployment
- Document any Vault configuration changes in the automation code
- **ALWAYS use vault_policy_document data sources for Vault policies**
- **NEVER use heredoc strings for policy definitions**
- All policies must be defined in a separate policies.tf file
- Use JWT authentication method for Vault Secrets Operator (HashiCorp recommendation)