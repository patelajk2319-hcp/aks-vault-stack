# Vault Logging Guide

This document explains the different types of logs available in the Vault deployment and how to access them.

## Types of Vault Logs

### 1. Vault Audit Logs (Application-Level)

**Purpose:** Track all authenticated API requests and responses to Vault.

**Location:** Stored in Vault's persistent storage:
- Main audit log: `/vault/data/audit.log` (general operations, excludes database creds)
- Database audit log: `/vault/data/audit_database.log` (database credential operations only)

**What's Logged:**
- All authenticated requests (path, operation, auth method)
- Request and response data
- Lease information (creation, renewal, revocation)
- Authentication attempts
- Policy checks

**Access Methods:**

```bash
# Export main audit logs as JSON
task audit-logs

# Query database credential lifecycle (creation, renewal, revocation)
task db-logs

# Query with custom limit (default: 10 records per section)
task db-logs limit=20
```

**Use Cases:**
- Compliance and security auditing
- Track who accessed what secrets and when
- Monitor lease lifecycles
- Investigate security incidents

### 2. Vault Operational Logs (Server-Level)

**Purpose:** Internal Vault server operations and diagnostics.

**Location:** Stdout/stderr of the Vault container (not persisted by default)

**What's Logged:**
- Server lifecycle events (startup, shutdown, seal/unseal)
- Internal operations (lease management, token creation)
- Secrets engine operations (database credential rotation, etc.)
- Performance and error diagnostics
- Warnings and errors

**Example Entries:**
```
[INFO]  secrets.database: rotating static credentials for role "app-role"
[INFO]  core: successfully mounted: type=database path=database/
[WARN]  core: failed to renew lease: lease_id=database/creds/readonly/abc123
[INFO]  expiration: lease restore complete
[INFO]  core: vault is sealed
```

**Access Methods:**

```bash
# View all Vault operational logs (real-time, last 100 lines)
task logs

# View database-related operational logs only (last 100 lines)
task operational-logs-db

# View more operational log lines
task operational-logs-db lines=500
```

**Use Cases:**
- Troubleshoot Vault server issues
- Monitor internal operations (credential rotation, lease management)
- Performance tuning
- Debugging configuration issues

### 3. VSO (Vault Secrets Operator) Logs

**Purpose:** Track VSO's interaction with Vault and Kubernetes.

**Location:** Stdout/stderr of the VSO container

**What's Logged:**
- Secret synchronisation events
- Vault authentication attempts
- Kubernetes secret creation/updates
- Errors and retries

**Access Methods:**

```bash
# View VSO logs (real-time)
task vso-logs
```

**Use Cases:**
- Troubleshoot secret sync issues
- Monitor VSO's credential refresh behaviour
- Debug authentication problems

## Log Configuration

### Audit Log Configuration

Audit devices are configured via Terraform:
- **File:** `terraform/vault-audit-devices/main.tf`
- **Filters:** Separate logs for general operations vs database credentials

### Operational Log Level

Operational log level is configured in the Vault Helm values:
- **File:** `helm-chart/vault-stack/values/vault/vault.yaml`
- **Setting:** `log_level = "info"` (options: trace, debug, info, warn, error)

**To enable debug logging:**

1. Edit `helm-chart/vault-stack/values/vault/vault.yaml`
2. Change `log_level = "info"` to `log_level = "debug"`
3. Redeploy Vault: `task rm && task up && task init`

**Warning:** Debug logging produces high log volumes. Only enable temporarily for troubleshooting.

## Comparison: Audit Logs vs Operational Logs

| Feature | Audit Logs | Operational Logs |
|---------|-----------|------------------|
| **Purpose** | Compliance & security auditing | Server diagnostics & operations |
| **Persistence** | Stored on disk | Ephemeral (stdout) |
| **Content** | API requests & responses | Internal server operations |
| **Format** | Structured JSON | Semi-structured text |
| **Use Case** | Who did what, when | How is Vault performing |
| **Database Rotation** | Shows lease creation/renewal requests | Shows internal rotation mechanics |

## Database Credential Rotation Visibility

To see the full picture of database credential rotation, you need both log types:

### Audit Logs (`task db-logs`)
- **What:** When VSO requests credentials from Vault
- **Shows:**
  - Credential creation (`database/creds/readonly` reads)
  - Lease renewal requests (`sys/leases/renew`)
  - Lease revocations (`sys/leases/revoke`)
- **Format:** Structured with timestamps, service accounts, lease IDs

### Operational Logs (`task operational-logs-db`)
- **What:** Internal Vault database secrets engine operations
- **Shows:**
  - Static credential rotation (if configured)
  - Database connection pool events
  - Internal rotation job scheduling
  - Database plugin operations
- **Format:** Log messages with severity levels

### VSO Logs (`task vso-logs`)
- **What:** How VSO manages the Kubernetes secret lifecycle
- **Shows:**
  - When VSO decides to refresh credentials (80% of TTL)
  - Kubernetes secret update operations
  - Sync errors and retries

## Example Workflow

To investigate database credential rotation:

```bash
# 1. Check audit logs for lease lifecycle
task db-logs limit=20

# 2. Check operational logs for internal operations
task operational-logs-db lines=200

# 3. Check VSO logs for sync behaviour
task vso-logs

# 4. Export raw audit data for analysis
task audit-logs  # Creates data/audit-logs.json
```

## Best Practices

1. **Regular Monitoring:** Periodically review logs for anomalies
2. **Log Retention:** Audit logs are persisted on PVCs; configure retention policies
3. **Debug Mode:** Only enable debug logging temporarily for troubleshooting
4. **Security:** Audit logs contain sensitive information; protect access appropriately
5. **Automation:** Consider exporting audit logs to external SIEM systems for long-term storage

## Troubleshooting

### "No database-related operational log entries found"

This is normal if:
- No database operations have occurred recently
- Log level is set too high (error/warn only)
- Using dynamic credentials (rotation logs are less frequent)

**Solution:** Increase log lines or change log level to debug.

### "Cannot connect to Vault"

Ensure port forwarding is active:
```bash
task port-forward
```

### Missing Audit Logs

Ensure audit devices are configured:
```bash
task audit
```
