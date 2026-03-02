locals {
  github_connector_ref = {
    account = "account.${var.github_connector}"
    org     = "org.${var.github_connector}"
    project = var.github_connector
  }
  is_flyway   = var.migration_type == "flyway"
  prefix      = local.is_flyway ? "flyway_" : ""
  name_prefix = local.is_flyway ? "Flyway " : ""
  db_svc_prefix = local.is_flyway ? "flyway-postgres" : "postgres"
  schema_id   = local.is_flyway ? "flyway_db" : "db1"
  schema_name = local.is_flyway ? "Flyway DB" : "DB"
}

resource "harness_platform_organization" "org" {
  count      = var.create_org ? 1 : 0
  identifier = var.organization
  name       = var.organization
}

resource "harness_platform_project" "project" {
  count      = var.create_project ? 1 : 0
  name       = var.project_name
  identifier = var.project_name
  org_id     = var.organization
  depends_on = [harness_platform_organization.org]
}

resource "harness_platform_secret_text" "inline" {
  identifier  = "${local.prefix}db1"
  name        = "${local.prefix}db1"
  org_id    = var.organization
  project_id = var.project_name
  depends_on = [
    harness_platform_project.project,
    harness_platform_organization.org,
  ]
  description = "example"
  tags        = ["foo:bar"]

  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = "secretpass"
}

resource "harness_platform_connector_jdbc" "db1" {
  identifier         = "${local.prefix}db1"
  name               = "${local.name_prefix}DB1"
  org_id    = var.organization
  project_id = var.project_name
  depends_on = [
    harness_platform_secret_text.inline,
  ]
  description        = ""
  url                = "jdbc:postgresql://${local.db_svc_prefix}-db1.${var.namespace}.svc.cluster.local:5432/mydb"
  delegate_selectors = [var.delegate_selector]
  credentials {
    auth_type = "UsernamePassword"
    username_password {
      username     = "admin"
      password_ref = "${local.prefix}db1"
    }
  }
}

resource "harness_platform_secret_text" "inline2" {
  identifier  = "${local.prefix}db2"
  name        = "${local.prefix}db2"
  org_id    = var.organization
  project_id = var.project_name
  depends_on = [
    harness_platform_project.project,
    harness_platform_organization.org,
  ]
  description = "example"
  tags        = ["foo:bar"]

  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = "secretpass"
}

resource "harness_platform_connector_jdbc" "db2" {
  identifier         = "${local.prefix}db2"
  name               = "${local.name_prefix}DB2"
  org_id    = var.organization
  project_id = var.project_name
  depends_on = [
    harness_platform_secret_text.inline2,
  ]
  description        = ""
  url                = "jdbc:postgresql://${local.db_svc_prefix}-db2.${var.namespace}.svc.cluster.local:5432/mydb"
  delegate_selectors = [var.delegate_selector]
  credentials {
    auth_type = "UsernamePassword"
    username_password {
      username     = "admin"
      password_ref = "${local.prefix}db2"
    }
  }
}

resource "harness_platform_secret_text" "inline3" {
  identifier  = "${local.prefix}db3"
  name        = "${local.prefix}db3"
  org_id    = var.organization
  project_id = var.project_name
  depends_on = [
    harness_platform_project.project,
    harness_platform_organization.org,
  ]
  description = "example"
  tags        = ["foo:bar"]

  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = "secretpass"
}

resource "harness_platform_connector_jdbc" "db3" {
  identifier         = "${local.prefix}db3"
  name               = "${local.name_prefix}DB3"
  org_id    = var.organization
  project_id = var.project_name
  depends_on = [
    harness_platform_secret_text.inline3,
  ]
  description        = ""
  url                = "jdbc:postgresql://${local.db_svc_prefix}-db3.${var.namespace}.svc.cluster.local:5432/mydb"
  delegate_selectors = [var.delegate_selector]
  credentials {
    auth_type = "UsernamePassword"
    username_password {
      username     = "admin"
      password_ref = "${local.prefix}db3"
    }
  }
}


resource "harness_platform_db_schema" "liquibase" {
  count          = local.is_flyway ? 0 : 1
  identifier     = "db1"
  org_id         = var.organization
  project_id     = var.project_name
  depends_on     = [harness_platform_project.project]
  name           = "DB"
  type           = "Repository"
  migration_type = "Liquibase"
  schema_source {
    connector = local.github_connector_ref[var.github_connector_scope]
    repo      = var.github_repo
    location  = "liquibase/changelog.yaml"
  }
}

resource "harness_platform_db_schema" "flyway" {
  count          = local.is_flyway ? 1 : 0
  identifier     = "flyway_db"
  org_id         = var.organization
  project_id     = var.project_name
  depends_on     = [harness_platform_project.project]
  name           = "Flyway DB"
  type           = "Repository"
  migration_type = "Flyway"
  schema_source {
    connector = local.github_connector_ref[var.github_connector_scope]
    repo      = var.github_repo
    location  = "flyway/migrations"
    toml      = "flyway/flyway.toml"
  }
}

resource "harness_platform_db_instance" "db1" {
  identifier  = "${local.prefix}db1"
  org_id     = var.organization
  project_id = var.project_name
  name        = "${local.name_prefix}DB1"
  depends_on = [
    harness_platform_db_schema.liquibase,
    harness_platform_db_schema.flyway,
    harness_platform_connector_jdbc.db1,
  ] 
  schema      = local.schema_id
  branch      = "main"
  connector   = "${local.prefix}db1"
}

resource "harness_platform_db_instance" "db2" {
  identifier  = "${local.prefix}db2"
  org_id     = var.organization
  project_id = var.project_name
  name        = "${local.name_prefix}DB2"
  depends_on = [
    harness_platform_db_schema.liquibase,
    harness_platform_db_schema.flyway,
    harness_platform_connector_jdbc.db2,
  ] 
  schema      = local.schema_id
  branch      = "main"
  connector   = "${local.prefix}db2"
}

resource "harness_platform_db_instance" "db3" {
  identifier  = "${local.prefix}db3"
  org_id     = var.organization
  project_id = var.project_name
  name        = "${local.name_prefix}DB3"
  depends_on = [
    harness_platform_db_schema.liquibase,
    harness_platform_db_schema.flyway,
    harness_platform_connector_jdbc.db3,
  ] 
  schema      = local.schema_id
  branch      = "main"
  connector   = "${local.prefix}db3"
}
