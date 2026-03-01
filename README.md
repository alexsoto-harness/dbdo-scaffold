# DB DevOps Workshop Setup

This repo contains the infrastructure and Terraform automation to provision a **Harness DB DevOps** workshop environment. It deploys 3 PostgreSQL databases into a Kubernetes cluster and configures all necessary Harness resources (secrets, JDBC connectors, DB schema, DB instances) via Terraform.

---

## Prerequisites

Before starting, ensure you have:

1. **A GKE cluster** (or any Kubernetes cluster) with `kubectl` access
2. **A Harness account** with the **CD & GitOps** and **DB DevOps** modules enabled
3. **A Harness Delegate** running in the target cluster
4. **A Kubernetes connector** in Harness pointing to the cluster (note the identifier)
5. **A GitHub connector** in Harness (can be at account, org, or project scope)
6. **A GitHub repo** containing a `changelog.yaml` file (see [Changelog Repo](#changelog-repo))
7. **A Harness API key** with project-admin permissions
8. **Terraform** installed locally (tested with Harness provider `0.37.4`)

---

## Changelog Repo

The workshop uses a separate GitHub repo to store Liquibase changelogs. This repo must contain a `changelog.yaml` at the root. A starter file is provided in `dbdo-sample-init/changelog.yaml` — push it to your changelog repo before running Terraform.

Example:
```yaml
databaseChangeLog:
  - changeSet:
      id: 2026-03-01-add-vendor-active-flag
      author: harness-lab
      changes:
        - addColumn:
            tableName: vendors
            columns:
              - column:
                  name: is_active
                  type: boolean
                  defaultValueBoolean: true
      rollback:
        - dropColumn:
            tableName: vendors
            columnName: is_active
```

---

## Step 1: Connect to Your Kubernetes Cluster

Point `kubectl` at your target cluster. For GKE:

```bash
gcloud container clusters get-credentials <CLUSTER_NAME> --region <REGION> --project <GCP_PROJECT>
```

Verify connectivity:
```bash
kubectl cluster-info
```

---

## Step 2: Deploy Databases

Pick a namespace name (e.g., `db-lab`). Each workshop participant should get their own namespace.

```bash
kubectl create namespace <NAMESPACE>
kubectl apply -n <NAMESPACE> -f seed-data.yaml
kubectl apply -n <NAMESPACE> -f dbs.yaml
```

This creates:
- **3 PostgreSQL 16 StatefulSets** (`postgres-db1`, `postgres-db2`, `postgres-db3`), each with a 10Gi PVC
- **3 ClusterIP Services** on port 5432
- **3 Init Jobs** that seed each database with `users`, `vendors`, and `transactions` tables plus sample data

Verify everything is running:
```bash
kubectl get pods,jobs -n <NAMESPACE>
```

All 3 `postgres-dbN-0` pods should be `Running` and all 3 `init-schema-dbN` jobs should be `Complete`.

**Connection details** (same for all 3 DBs):
- **User:** `admin`
- **Password:** `secretpass`
- **Database:** `mydb`
- **Host:** `postgres-dbN.<NAMESPACE>.svc.cluster.local`
- **Port:** `5432`

---

## Step 3: Run Terraform to Provision Harness Resources

### Set Environment Variables

```bash
export HARNESS_ACCOUNT="<your-harness-account-id>"
export HARNESS_KEY="<your-harness-api-key>"
```

### Initialize and Apply

```bash
cd terraform/
terraform init
terraform apply \
  -var="key=$HARNESS_KEY" \
  -var="account=$HARNESS_ACCOUNT"
```

### Terraform Variables

All variables have sensible defaults. Override as needed:

| Variable | Default | Description |
|---|---|---|
| `project_name` | `Reference_Architecture` | Harness project identifier |
| `create_project` | `false` | Set `true` to create the project (set `false` to use an existing one) |
| `organization` | `default` | Harness org identifier |
| `create_org` | `false` | Set `true` to create the org (set `false` to use an existing one) |
| `namespace` | `db-lab` | Kubernetes namespace where the DBs are running |
| `github_repo` | `alexsoto-harness/dbdo-sample` | GitHub repo containing the `changelog.yaml` |
| `github_connector` | `Harness_Github` | Identifier of the GitHub connector in Harness |
| `github_connector_scope` | `account` | Scope of the GitHub connector: `account`, `org`, or `project` |
| `k8s_connector` | `harnesstrcluster` | Identifier of the Kubernetes connector in Harness (used in labs) |
| `k8s_connector_scope` | `account` | Scope of the K8s connector: `account`, `org`, or `project` |

### Example: Full Custom Apply

```bash
terraform apply \
  -var="key=$HARNESS_KEY" \
  -var="account=$HARNESS_ACCOUNT" \
  -var="project_name=MyWorkshop" \
  -var="create_project=true" \
  -var="namespace=my-namespace" \
  -var="organization=my-org" \
  -var="github_repo=myuser/my-changelog-repo" \
  -var="github_connector=My_GH_Connector" \
  -var="github_connector_scope=org" \
  -var="k8s_connector=my-k8s-connector" \
  -var="k8s_connector_scope=project"
```

### What Terraform Creates

- **Harness Project** (optional — only if `create_project=true`)
- **3 Secrets** (`db1`, `db2`, `db3`) — PostgreSQL passwords
- **3 JDBC Connectors** (`DB1`, `DB2`, `DB3`) — pointing to each database in the cluster
- **1 DB Schema** (`DB`) — linked to the changelog repo via the GitHub connector
- **3 DB Instances** (`DB1`, `DB2`, `DB3`) — each linked to the schema and its JDBC connector

---

## Step 4: Run the Workshop Labs

Follow the **[Lab Guide](LAB_GUIDE.md)** to complete the 4 hands-on labs:

| Lab | Topic | What You'll Do |
|---|---|---|
| **Lab 1** | Deploy a Change | Create a pipeline, add a Git trigger, push a changelog |
| **Lab 2** | Roll Back a Change | Add a rollback step, push a breaking change, see auto-recovery |
| **Lab 3** | Enforce Governance | Create an OPA policy, block a `DROP TABLE` at runtime |
| **Lab 4** | Multi-Environment Orchestration | Promote changes through Dev → QA → Prod in one pipeline |

> **Note:** When the labs ask you to select a **Kubernetes cluster connector** for containerized step group execution, use the connector specified by `k8s_connector` (default: `harnesstrcluster`). The labs may reference `DBDevOps` — use your own connector instead. The K8s connector is not managed by Terraform and must already exist in Harness.

---

## Teardown

To remove all resources:

```bash
# Destroy Harness resources
cd terraform/
terraform destroy \
  -var="key=$HARNESS_KEY" \
  -var="account=$HARNESS_ACCOUNT"

# Remove Kubernetes resources
kubectl delete namespace <NAMESPACE>
```
