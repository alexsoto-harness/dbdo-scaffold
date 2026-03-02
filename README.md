# Harness DB DevOps Workshop

This repository contains everything needed to run the Harness Database DevOps workshop. It supports two migration tools — choose the one that matches your preferred workflow.

## Workshop Options

| Option | Migration Tool | Directory | Description |
|--------|---------------|-----------|-------------|
| **Liquibase** | Liquibase | `liquibase/` | YAML-based changelogs with inline rollback blocks |
| **Flyway** | Flyway | `flyway/` | SQL-first versioned migrations with undo scripts |

Both options cover the same 4 labs:

1. **Deploy a Change** — push a schema change and watch the pipeline apply it
2. **Roll Back a Change** — trigger a failure and observe automatic rollback
3. **Enforce Governance** — block destructive SQL with OPA policies
4. **Multi-Environment Orchestration** — deploy across Dev, QA, and Production

## Getting Started

1. Choose your migration tool (Liquibase or Flyway)
2. Follow the setup instructions in the corresponding `README.md`:
   - [Liquibase Setup](liquibase/README.md)
   - [Flyway Setup](flyway/README.md)
3. Work through the lab guide:
   - [Liquibase Lab Guide](liquibase/LAB_GUIDE.md)
   - [Flyway Lab Guide](flyway/LAB_GUIDE.md)

## Shared Infrastructure

The following resources are shared across both options:

- **`seed-data.yaml`** — ConfigMap with initial SQL schema (users, vendors, transactions tables)
- **`dbs.yaml`** — Kubernetes manifests for Liquibase Postgres pods (DB1, DB2, DB3)
- **`flyway-dbs.yaml`** — Kubernetes manifests for Flyway Postgres pods (Flyway-DB1, Flyway-DB2, Flyway-DB3)
- **`terraform/`** — Harness resource provisioning (supports both via `migration_type` variable)

## Terraform

The Terraform configuration uses a `migration_type` variable to switch between Liquibase and Flyway:

```bash
# For Liquibase (default)
terraform apply

# For Flyway
terraform apply -var="migration_type=flyway"
```

This controls:
- Resource naming (Flyway resources get a `flyway_` prefix)
- DB Schema creation method (TF provider for Liquibase, Harness API for Flyway)
- JDBC connector URLs (pointing to the correct Postgres pods)

## Sample Repo Structure

The companion repo (`dbdo-sample`) has the following structure:

```
dbdo-sample/
├── liquibase/
│   └── changelog.yaml          # Liquibase YAML changelogs
└── flyway/
    ├── migrations/
    │   ├── V1__description.sql  # Versioned migrations
    │   └── U1__description.sql  # Undo migrations
    └── flyway.toml              # Flyway configuration
```
