# DB DevOps Workshop — Lab Guide (Flyway)

This guide walks through 4 hands-on labs covering the full lifecycle of database change management using **Harness DB DevOps** with **Flyway**. By the end, you'll have deployed, rolled back, governed, and orchestrated schema changes across multiple environments.

> **Prerequisites:** Complete all setup steps in [README.md](README.md) before starting the labs. You should have 3 running PostgreSQL databases (Flyway variants), Terraform-provisioned Harness resources, and access to the Harness UI.

---

## Lab 1: Deploy a Change

**Key Outcomes:** No friction for developers, automated schema changes via Git.

### Overview

You'll create a pipeline that applies a Flyway migration to a target database, set up a Git trigger so changes deploy automatically on push, then push a new migration file to see it applied end-to-end.

### Step 1: Create a Deployment Pipeline

1. In the Harness UI, go to **Pipelines**
2. Click **Create a Pipeline**, name it `Deploy DB Schema`, click **Start**
3. Click **Add Stage** → choose **Custom Stage**, name it `Deploy Dev`
4. Click **Add Step Group**, name it `DB`, then enable **Containerized Execution**
5. Select your Kubernetes cluster connector where the step should run. Use your own connector instead (see `k8s_connector` in the [README](README.md#terraform-variables))

### Step 2: Add the Schema Deployment Step

1. Inside your stage, click **Add Step**
2. Search for and select **Apply Schema** (under DB DevOps), name it `Apply Change`
3. In the step configuration:
   - **Schema:** `Flyway DB`
   - **Database Instance:** `Flyway DB1`
   - **Migration Type:** `Flyway`
4. Click **Apply Changes**

### Step 3: Save and Test the Pipeline

1. Click **Save** to finalize the pipeline
2. Click **Run** to manually execute it
3. Verify that:
   - The schema changes are applied to the target database
   - The pipeline completes successfully

### Step 4: Enable Automatic Git-Based Deployment

1. Navigate to your pipeline and click **Triggers** (top tab) → **+ New Trigger**
2. Under **Webhook**, select **GitHub**
3. Name it: `On Push`
4. Under **Connector**, select your GitHub connector (`Harness_Github` at account scope)
5. Set **Repository Name** to your migration repo (e.g., `dbdo-sample`)
6. Under **Event**, select **Push**
7. Click **Continue**
8. Under **Conditions**:
   - Set **Branch Name** to `main`
   - Under **Changed Files**, enter `flyway/migrations/`
9. Click **Continue** through the remaining steps, then **Create Trigger**

> **Note:** If your GitHub connector uses a GitHub App or has webhook permissions, Harness will auto-register the webhook on GitHub. If it uses a PAT without webhook permissions, you may need to manually add the webhook URL (shown after trigger creation) to your GitHub repo under **Settings → Webhooks**.

### Step 5: Push a Migration to Git

1. In your local clone of the migration repo (or edit directly on GitHub)
2. Create a new file `flyway/migrations/V2__add_second_email_column.sql`:

```sql
ALTER TABLE users ADD COLUMN second_email VARCHAR(255);
```

3. Also create the undo file `flyway/migrations/U2__undo_add_second_email_column.sql`:

```sql
ALTER TABLE users DROP COLUMN second_email;
```

4. Commit and push to `main`
5. The pipeline will automatically trigger and apply the migration

> **Best Practice:** Always create the undo migration (`U<version>`) alongside the versioned migration (`V<version>`). This ensures rollback is always available.

### Value Callouts

- **Familiar Workflow** — developers stay in Git, no context-switching
- **SQL-First** — write plain SQL, no XML or YAML abstraction layer
- **Accelerated Velocity** — no waiting on tickets or DBAs

---

## Lab 2: Roll Back a Change

**Key Outcomes:** Safe failure handling, pre-validated rollback plans, confidence in change velocity.

### Overview

You'll intentionally deploy a breaking change. The pipeline detects the failure and automatically triggers a rollback using Flyway's undo migration — no manual intervention required.

### Step 1: Add a Rollback Step

1. Navigate to your pipeline and locate the step group containing the **Apply Schema** step
2. Hover on the line after the apply step and click the **+** icon to add a new step to the right
3. Search for **Rollback Schema** and select it
4. In the step configuration:
   - **DB Schema:** `Flyway DB`
   - **Database Instance:** `Flyway DB1`
   - **Rollback Tag:** `<+execution.steps.DB.steps.Apply_Change.output.preStartTag>`
5. Add a **Conditional Execution**:
   - Navigate to the **Advanced** tab
   - Click **Conditional Execution**
   - Choose **If the previous step fails**
6. Click **Apply Changes**, then **Save** the pipeline

> **Why `preStartTag` instead of `Rollback Count`?** The Apply Schema step automatically tags the database state *before* applying any changes. The `preStartTag` output captures that tag. Using it in the Rollback step ensures we only revert changes made in the current run — never touching previous successful deployments. `Rollback Count: 1` is simpler but can accidentally roll back a change from a prior run if the current run applied multiple migrations before failing.

### Step 2: Push a Breaking Change to Git

Create a migration that attempts an invalid change (adding a column that already exists):

1. Create `flyway/migrations/V3__add_duplicate_id_column.sql`:

```sql
ALTER TABLE users ADD COLUMN id INT;
```

2. Create `flyway/migrations/U3__undo_add_duplicate_id_column.sql`:

```sql
ALTER TABLE users DROP COLUMN id;
```

3. Commit and push to `main`

### What Happens

1. The pipeline triggers automatically
2. The Apply Schema step tags the database, then attempts to apply the breaking migration
3. The apply **fails** — the rollback step executes automatically
4. The rollback reverts to the `preStartTag`, restoring the database to its pre-deployment state

### Value Callouts

- **Automatic Rollbacks** — undo migrations are pre-validated and ready to run
- **No Manual Intervention** — no need to SSH in or dig up old scripts
- **Resilience as Default** — pipelines fail gracefully, keeping environments stable

---

## Lab 3: Enforce Governance and Policy

**Key Outcomes:** Targeted policy-as-code enforcement, standardized review gates, risk mitigation before deployment.

### Overview

You'll create an OPA policy that blocks destructive SQL (e.g., `DROP TABLE`). When a disallowed change is pushed, the pipeline evaluates it and immediately blocks execution.

### Step 1: Create a Policy

1. In the left-hand panel, go to **Project Settings**
2. Select **Policies**, then click **New Policy**
   - You may need to click the **X** in the upper right to dismiss a pop-up
3. Name the policy: `Block Destructive SQL`
4. Paste the following and click **Save**:

```rego
package db_sql

rules := [
  {
    "types": ["mssql","oracle","postgres","mysql"],
    "environments": ["prod"],
    "regex": [
      "drop\\s+table",
      "drop\\s+column",
      "drop\\s+database",
      "drop\\s+schema"
    ]
  },{
    "types": ["oracle"],
    "environments": ["prod"],
    "regex": ["drop\\s+catalog"]
  }
]

deny[msg] {
  some i, k, l
  rule := rules[i]
  regex.match(concat("",[".*",rule.regex[k],".*"]), lower(input.sqlStatements[l]))
  msg := "dropping data is not permitted"
}
```

### Step 2: Create a Policy Set

1. Click **Policy Sets** → **New Policy Set**
2. Name it: `Prevent Destructive Changes`
3. Under **Entity Type**, select **Custom**
4. Under **Event**, select **On Step**
5. Click **Continue**
6. Under **Policy to Evaluate**, click **Add Policy**
7. Select `Block Destructive SQL`
8. Set the evaluation mode to **Error and Exit**
9. Click **Apply**, then **Finish**
10. If necessary, toggle **Enforce** to on

### Step 3: Attach the Policy to the Pipeline

1. Open the **Apply Change** step in your pipeline
2. Switch to the **Advanced** tab
3. Expand the **Policy Enforcement** section
4. Select `Prevent Destructive Changes` policy set from the **Project** scope
5. Click **Apply Changes**, then **Save Pipeline**

### Step 4: Push a Disallowed Change to Git

Create a migration that violates the policy:

1. Create `flyway/migrations/V4__drop_users_table.sql`:

```sql
DROP TABLE users;
```

2. Commit and push to `main`

### What Happens

1. The pipeline triggers automatically
2. The policy evaluates the SQL before deployment
3. Execution **fails** with: `dropping data is not permitted`
4. The database is never touched

> **Note:** The OPA policy works identically for both Liquibase and Flyway — Harness passes the same `input.sqlStatements` payload to the policy engine regardless of the migration tool.

### Value Callouts

- **Guardrails, Not Roadblocks** — issues surface early without slowing compliant developers
- **Policy-as-Code** — governance is version-controlled like everything else
- **Risk Reduction** — unsafe changes caught before they affect production

---

## Lab 4: Orchestrate Changes Across Multiple Environments

**Key Outcomes:** Single pipeline for multi-env DB deployments, environment-specific guardrails, reduced handoffs.

### Overview

You'll promote a database change through Dev → QA → Production using a single pipeline. Each stage applies the change to a different target database with its own configuration.

### Step 1: Add QA Stage (Flyway DB2)

1. In your existing pipeline, click **Add Stage** → **Custom Stage**, name it `Deploy QA`
2. Click **Add Step Group**, name it `DB`, enable **Containerized Execution**
3. Select your Kubernetes cluster connector (Use your own, see `k8s_connector` in [README](README.md#terraform-variables))
4. Click **Add Step** → **Apply Schema** (under DB DevOps)
5. Name the step: `Deploy Database Schema - QA`
6. Configuration:
   - **Schema:** `Flyway DB`
   - **Database Instance:** `Flyway DB2`
   - **Migration Type:** `Flyway`
7. Click **Apply Changes**

### Step 2: Add Production Stage (Flyway DB3)

1. Click **Add Stage** → **Custom Stage**, name it `Deploy Prod`
2. Click **Add Step Group**, name it `DB`, enable **Containerized Execution**
3. Select your Kubernetes cluster connector (same as above, use your own)
4. Click **Add Step** → **Apply Schema**
5. Name the step: `Deploy Database Schema - Prod`
6. Configuration:
   - **Schema:** `Flyway DB`
   - **Database Instance:** `Flyway DB3`
   - **Migration Type:** `Flyway`
7. Click **Apply Changes**

### Step 3: Clean Up and Run the Pipeline

1. Click **Save** to finalize the multi-stage pipeline
2. In Git, **remove** any breaking migration files from previous labs:
   - Delete `flyway/migrations/V3__add_duplicate_id_column.sql` and `flyway/migrations/U3__undo_add_duplicate_id_column.sql` (from Lab 2)
   - Delete `flyway/migrations/V4__drop_users_table.sql` (from Lab 3)
3. Commit and push to `main` to kick off the pipeline
4. Observe the deployment through all 3 stages:
   - **Stage 1:** Flyway DB1 (Dev)
   - **Stage 2:** Flyway DB2 (QA)
   - **Stage 3:** Flyway DB3 (Production)
5. Verify successful execution in all stages

### Step 4: View Schema Overview

1. From the left-hand nav, go to **Overview**
2. Observe the green checkmarks next to Dev, QA, and Production, indicating:
   - Where the change has been applied
   - That each deployment completed successfully
3. This provides visibility across all environments from a single pane of glass

### Value Callouts

- **Unified Workflow** — one pipeline governs the full lifecycle from dev to prod
- **Environment-Specific Control** — each stage can have its own policies, approvers, and rollback settings
- **Schema Visibility** — the Harness UI shows which schema changes have been applied where
- **Production Readiness by Design** — staged rollouts ensure only validated changes reach production
