# Flyway CLI Pipeline

This directory contains resources for running Flyway migrations using native CLI commands in Harness pipelines — **without** the DB DevOps module. Instead, it uses the `redgate/flyway` Docker image and Harness Run steps.

## Why?

The DB DevOps module provides a managed experience (Apply Schema, Rollback Schema steps). This CLI approach gives you full control over Flyway commands, making it useful for:

- Teams that want to replicate existing CI/CD workflows (e.g., GitHub Actions, GitLab CI)
- Running Flyway commands not available in the DB DevOps module (e.g., `validate`, `info`, `clean`, `check`)
- Building custom pipeline logic around Flyway operations

## Architecture

```
Pipeline: Flyway CLI Migrate
└── Stage: Deploy Dev (Custom Stage)
    └── Step Group: Flyway (Containerized, K8s)
        ├── Git Clone (fetch migration repo)
        ├── Run: flyway info (redgate/flyway image)
        └── Run: flyway migrate (redgate/flyway image)
```

## Infrastructure

- **Database:** Single Postgres 16 pod (`cli-postgres-db1`) in `db-lab` namespace
- **Docker Image:** `redgate/flyway` (supports Community, Teams, and Enterprise)
- **No Harness DB DevOps resources needed** — no DB Schema, DB Instance, or JDBC connectors

## Setup

### 1. Deploy the CLI Database

```bash
# Ensure seed data ConfigMap exists (shared with other labs)
kubectl apply -f seed-data.yaml -n db-lab

# Deploy CLI Postgres DB
kubectl apply -f cli/cli-db.yaml -n db-lab

# Verify pod is running
kubectl get pods -n db-lab -l app=cli-postgres-db1
```

### 2. Migration Repo Structure

The sample repo (`cli` branch) contains:

```
cli/
├── flyway.toml        # Flyway config with default environment pointing to CLI DB
└── migrations/
    ├── V1__add_vendor_active_flag.sql
    └── U1__undo_add_vendor_active_flag.sql
```

### 3. Create the Pipeline in Harness

1. Create a new pipeline: `Flyway CLI Migrate`
2. Add a **Custom Stage**: `Deploy Dev`
3. Add a **Step Group**: `Flyway`, enable **Containerized Execution**
4. Select your K8s cluster connector
5. Add steps:

**Step 1: Git Clone**
- Connector: Your GitHub connector
- Repository: Your sample repo
- Branch: `cli`

**Step 2: Run — Flyway Info**
- Container Registry: `Harness Docker`
- Image: `redgate/flyway`
- Command:
```bash
flyway info \
  -configFiles=cli/flyway.toml \
  -locations="filesystem:cli/migrations" \
  -password=secretpass
```

**Step 3: Run — Flyway Migrate**
- Container Registry: `Harness Docker`
- Image: `redgate/flyway`
- Command:
```bash
flyway migrate \
  -configFiles=cli/flyway.toml \
  -locations="filesystem:cli/migrations" \
  -password=secretpass
```

> **Note:** The password is passed via CLI flag here for simplicity. In production, use a Harness secret: `<+secrets.getValue("cli_db_password")>`

## Flyway CLI Commands Reference

| Command | Edition | Description |
|---------|---------|-------------|
| `info` | Community | Show migration status |
| `migrate` | Community | Apply pending migrations |
| `validate` | Community | Validate migration checksums |
| `repair` | Community | Fix schema history table |
| `clean` | Community | Drop all objects (destructive!) |
| `undo` | Teams+ | Revert last migration |
| `check` | Enterprise | Generate change/drift reports |

## Future Iterations

1. **Step Templates** — Parameterized Harness templates for each Flyway command
2. **AutoPilot Pipeline** — Multi-stage Build → Test → Prod pipeline modeled after [Red Gate's GitHub Actions workflow](https://github.com/red-gate/Flyway-AutoPilot-PG)
