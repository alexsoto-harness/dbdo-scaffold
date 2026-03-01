locals {
  github_connector_ref = {
    account = "account.${var.github_connector}"
    org     = "org.${var.github_connector}"
    project = var.github_connector
  }
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
  identifier  = "db1"
  name        = "db1"
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
  identifier         = "db1"
  name               = "DB1"
  org_id    = var.organization
  project_id = var.project_name
  depends_on = [
    harness_platform_secret_text.inline,
  ]
  description        = ""
  url                = "jdbc:postgresql://postgres-db1.${var.namespace}.svc.cluster.local:5432/mydb"
  delegate_selectors = [var.delegate_selector]
  credentials {
    auth_type = "UsernamePassword"
    username_password {
      username     = "admin"
      password_ref = "db1"
    }
  }
}

resource "harness_platform_secret_text" "inline2" {
  identifier  = "db2"
  name        = "db2"
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
  identifier         = "db2"
  name               = "DB2"
  org_id    = var.organization
  project_id = var.project_name
  depends_on = [
    harness_platform_secret_text.inline2,
  ]
  description        = ""
  url                = "jdbc:postgresql://postgres-db2.${var.namespace}.svc.cluster.local:5432/mydb"
  delegate_selectors = [var.delegate_selector]
  credentials {
    auth_type = "UsernamePassword"
    username_password {
      username     = "admin"
      password_ref = "db2"
    }
  }
}

resource "harness_platform_secret_text" "inline3" {
  identifier  = "db3"
  name        = "db3"
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
  identifier         = "db3"
  name               = "DB3"
  org_id    = var.organization
  project_id = var.project_name
  depends_on = [
    harness_platform_secret_text.inline3,
  ]
  description        = ""
  url                = "jdbc:postgresql://postgres-db3.${var.namespace}.svc.cluster.local:5432/mydb"
  delegate_selectors = [var.delegate_selector]
  credentials {
    auth_type = "UsernamePassword"
    username_password {
      username     = "admin"
      password_ref = "db3"
    }
  }
}


resource "harness_platform_db_schema" "db1" {
  identifier = "db1"
  org_id     = var.organization
  project_id = var.project_name
  depends_on = [
    harness_platform_project.project,
  ] 
  name       = "DB"
  schema_source {
    connector    = local.github_connector_ref[var.github_connector_scope]
    repo         = var.github_repo
    location     = "changelog.yaml"
  }
}

resource "harness_platform_db_instance" "db1" {
  identifier  = "db1"
  org_id     = var.organization
  project_id = var.project_name
  name        = "DB1"
  depends_on = [
    harness_platform_db_schema.db1,
    harness_platform_connector_jdbc.db1,
  ] 
  schema      = "db1"
  branch      = "main"
  connector   = "db1"
}

resource "harness_platform_db_instance" "db2" {
  identifier  = "db2"
  org_id     = var.organization
  project_id = var.project_name
  name        = "DB2"
  depends_on = [
    harness_platform_db_schema.db1,
    harness_platform_connector_jdbc.db2,
  ] 
  schema      = "db1"
  branch      = "main"
  connector   = "db2"
}

resource "harness_platform_db_instance" "db3" {
  identifier  = "db3"
  org_id     = var.organization
  project_id = var.project_name
  name        = "DB3"
  depends_on = [
    harness_platform_db_schema.db1,
    harness_platform_connector_jdbc.db3,
  ] 
  schema      = "db1"
  branch      = "main"
  connector   = "db3"
}
