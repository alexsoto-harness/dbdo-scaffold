# Lab 1: Deploy a Change

## Key Outcomes

No friction for developers

Automated changes

### Overview

In this lab, the user sets up a pipeline integrating a schema source, a target database, change application steps, and built-in change management.

The user then pushes a new database changelog to Git (e.g., adding a column). This triggers the pipeline and creates a pull request review step for the database change, just like any other code change.

### Walkthrough



#### Step 1: Create a Deployment Pipeline

In the Harness UI, go to Pipelines.

Click Create a Pipeline, enter a name (Deploy DB Schema), and click Start.

Click Add Stage and choose Custom Stage, enter a name (Deploy Dev).

Click Add Step Group, enter a name (DB), then enable the Containerized Stage.

Select the Kubernetes cluster (DBDevOps) where the step should run.



#### Step 2: Add the Schema Deployment Step

Inside your stage, click Add Step.

Search for and select Apply Schema (under DB DevOps), enter a name (Apply Change).

In the step configuration:

Schema: DB

Database Instance: DB1

Click Apply Changes.



#### Step 3: Save and Test the Pipeline

Click Save to finalize the pipeline.

Click Run to manually execute it.

Verify that:

The schema changes are applied to the target database.

The pipeline completes successfully.



#### Step 4: Enable Automatic Git-Based Deployment

Navigate to your pipeline and click Triggers, then New Trigger.

Choose Harness as the trigger type.

Enter a name (Update)

Select the repository (db_changes) used in your DB Schema definition.

Select Event (Push)

Under Conditions:

Set the branch name(s) (main) to monitor.

Under Changed Files, enter the path to your changelog file (changelog.yaml)

Continue, then Create Trigger



#### Step 6: Push a Changelog to Git

In your configured Git repo:

Add a changeSet to alter the schema



```yaml
databaseChangeLog:
- changeSet:
id: add-second-email-column
author: harness-lab
changes:
- addColumn:
tableName: users
columns:
- column:
name: second_email
type: varchar(255)
constraints:
nullable: true

Commit and push the change to the monitored branch.
The pipeline will automatically trigger:
The schema change will be applied to the target database.


Value Callouts
Familiar Workflow: Developers stay in Git — avoiding the need to learn or context-switch into a new tool just for database changes.
Single Source of Truth: All changes, including infrastructure and application code, are versioned together, promoting consistency and reducing drift.
Lower Learning Curve: Aligned with modern DevOps and GitOps standards, so new team members require minimal training to contribute.
Accelerated Velocity: No waiting on tickets or DBAs to manually apply scripts — changes are integrated directly into the development flow.
Compliance by Design: Compliance is de-risked when developers can operate within low-friction, automated, policy-driven workflows.

```

# Lab 2: Roll Back a Change

## Key Outcomes

Safe failure handling

Pre-validated rollback plans

Confidence in change velocity

### Overview

In this lab, the user intentionally deploys a database changelog that introduces a breaking or invalid change (e.g., dropping a required column). The pipeline detects the failure during deployment to a non-prod environment and automatically triggers a rollback using a pre-defined backout script.

This simulates a real-world scenario where a change fails validation or breaks application behavior, and highlights how Harness enables recovery without manual intervention or firefighting.

### Walkthrough

#### Step 1 Add a Rollback Step

Navigate to your pipeline, and locate the step group containing your DBSchemaApply step.



Hover below the apply step and click the ➕ icon to add a new step.

In the search bar, type rollback, and select the DBSchemaRollback step.

In the step configuration panel:

Set DB Schema to DB1

Set Database Instance to db1

Set Rollback Count to 1

Click Apply Changes, then Save the pipeline.



#### Step 2 Push a Breaking Change to Git

In your configured Git repo, add a changeSet that attempts to make an invalid change.

- changeSet:

id: add-duplicate-column

author: harness-lab

changes:

- addColumn:

tableName: users

columns:

- column:

name: id

type: int

rollback:

- sql:

comment: This is a no-op rollback for the invalid column addition.

sql: SELECT 1;





The pipeline will automatically trigger:

The breaking change will attempt to apply and fail.

The rollback plan will be executed automatically.

The environment will be restored to a stable state.



Value Callouts

Automatic Rollbacks: Backout plans are pre-validated and ready to run — reducing mean time to recovery (MTTR).

No Manual Intervention: Developers don’t need to SSH into environments or dig up old scripts — rollback is part of the pipeline.

Resilience as Default: Pipelines are designed to fail gracefully, keeping environments stable and deploy-ready.



# Lab 3: Enforce Governance and Policy

## Key Outcomes

Targeted policy-as-code enforcement

Standardized review and approval gates

Risk mitigation before deployment

### Overview

In this lab, the user attempts to push a database changelog that drops a table — a disallowed action in this environment. The pipeline evaluates the change using integrated policy-as-code (OPA) rules and immediately blocks execution.

The user reviews the policy failure, understands the violation, and updates the changelog to meet organizational standards before resubmitting.

### Walkthrough

#### Step 1: Create a Policy

In the left hand panel, go to Project Settings.

Select Policies, then click New Policy.

You may have to click the X in the upper right to dismiss a pop-up.

Name the policy Block Destructive SQL

In the policy editor, paste the following content and click save

```rego
package db_sql

```

```rego
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

```

```rego
deny[msg] {
some i, k, l
rule := rules[i]
regex.match(concat("",[".*",rule.regex[k],".*"]), lower(input.sqlStatements[l]))
msg := "dropping data is not permitted"
}

```

#### Step 2: Create a Policy Set

Click Policy Sets, then click New Policy Set.

Name the Policy Set: Prevent Destructive Changes.

Under Entity Type, select Custom.

Under Event, select On Run.

Click Continue.

Under Policy to Evaluate, click Add Policy.

Select the Block Destructive SQL policy.

Set the evaluation mode to Error and Exit.

Click Apply, then Finish.

If necessary, toggle Enforce.

In the pipeline:

Open the Apply Change step.

Switch to the advanced tab and expand the Policy Enforcement section.

Select Prevent Destructive Changes policy set from the Project scope.

Click Apply Changes.

Save Pipeline.

The new Policy Set is now active and will enforce the policy at pipeline runtime.



#### Step 3: Push a Disallowed Change to Git

In your configured Git repo, add a changeSet that violates the policy (attempting to drop a table)

Commit and push the change to the monitored branch (main).

```yaml
databaseChangeLog:
- changeSet:
id: 2025-05-21-drop-users-table
author: harness-lab
changes:
- dropTable:
tableName: users

Observe that:
The policy is triggered as part of the pipeline execution.
The execution fails before deployment.
The pipeline halts with the error:
 dropping data is not permitted
Value Callouts
Guardrails, Not Roadblocks: Policies surface issues early without slowing down developers who follow best practices.
Standardized Governance: Approval workflows and checks are consistent across teams, environments, and databases.
Policy-as-Code: Governance is defined in code and version-controlled — just like everything else.
Risk Reduction: Disallowed or unsafe changes are caught before they affect production.
Scalable Compliance: Teams can move fast while meeting security and audit requirements at scale.

```

# Lab 4: Orchestrate Changes Across Multiple Environments

## Key Outcomes

Single pipeline for multi-env DB deployments

Environment-specific guardrails

Reduced handoffs and manual coordination

### Overview

In this lab, the user promotes a database change through multiple environments — dev, staging, and production — using a single orchestrated pipeline. Each stage applies the change to a different target database with environment-specific configurations, policies, and approval steps.

As changes progress, the user can view which schema versions are deployed in each environment directly in the Harness UI — removing the need to manually track or document status.



### Walkthrough



#### Step 1: Add QA Stage (DB2)

In your existing pipeline from Lab 1, click Add Stage and choose Custom Stage, enter a name (Deploy QA).

Click Add Step Group, enter a name (DB), then enable the Containerized Stage.

Select the Kubernetes cluster (DBDevOps) where the step should run.

Inside the stage, click Add Step and select DBSchemaApply (under DB DevOps).

Name the step: Deploy Database Schema - QA.

In the step configuration:

Schema: DB

Database Instance: DB2

Click Apply Changes.



#### Step 2: Add Production Stage (DB3)

In your existing pipeline from Lab 1, click Add Stage and choose Custom Stage, enter a name (Deploy Prod).

Click Add Step Group, enter a name (DB), then enable the Containerized Stage.

Inside the stage, click Add Step and select DBSchemaApply.

Name the step: Deploy Database Schema - Prod.

In the step configuration:

Schema: DB

Database Instance: DB3

Click Apply Changes.



#### Step 3: Save and Run the Pipeline

Click Save to finalize the multi-stage pipeline.

In git, remove the table drop change, and the broken change from lab 2, then commit to kick off the pipeline.

Observe the deployment of the previously committed schema change through:

Stage 1: DB1 (Dev)

Stage 2: DB2 (QA)

Stage 3: DB3 (Production)

Verify successful execution in all stages.



#### Step 4: View Schema Overview

From the left-hand nav, go to Overview.

Observe the green checkmarks next to Dev, QA, and Production, indicating:

Where the change has been applied

That each deployment completed successfully

This provides visibility across all environments from a single pane of glass.





Value Callouts

Unified Workflow: One pipeline governs the full lifecycle of a database change from dev to prod.

Environment-Specific Control: Each stage can have its own policies, approvers, and rollback settings.

Schema Visibility: The Harness UI shows which schema changes have been applied where, so teams always know the current state across environments.

Reduced Toil: No need to manually coordinate between environments or hand off to DBAs.

Production Readiness by Design: Staged rollouts and approvals ensure only validated changes reach production.

