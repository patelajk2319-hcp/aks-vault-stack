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

## Critical Deployment Workflow

**ALWAYS run these commands in order for ANY deployment or infrastructure change:**

1. `task rm` - Remove the entire stack (clears cluster resources, keeps AKS)
2. `task infra` - Deploys the Azure infrastructure including AKS
3. `task up` - Deploys Vault Enterprise onto AKS
4. `task init` - Initialise Vault
5. `task unseal` - Unseal Vault


## Infrastructure Standards

### Terraform Requirements:
- **ONLY use official Terraform providers** (published by HashiCorp or the vendor themselves)
- **NEVER use community providers**
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

## Vault Configuration:
- Vault initialisation and unsealing are critical final steps
- Never skip these steps after deployment
- Document any Vault configuration changes in the automation code