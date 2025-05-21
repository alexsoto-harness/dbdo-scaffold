resource "harness_platform_project" "project" {  
    name      = var.project_name 
    identifier = var.project_name  
    org_id    = "default"  
}

resource "harness_platform_secret_text" "pl_key" {
  identifier  = "key"
  name        = "key"
  org_id    = "default"  
  project_id = var.project_name
  depends_on = [
    harness_platform_project.project,
  ]
  description = "example"
  tags        = ["foo:bar"]

  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = "${var.key}"
}

resource "harness_platform_secret_text" "inline" {
  identifier  = "db1"
  name        = "db1"
  org_id    = "default"  
  project_id = var.project_name
  depends_on = [
    harness_platform_project.project,
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
  org_id    = "default"  
  project_id = var.project_name
  depends_on = [
    harness_platform_secret_text.inline,
  ]
  description        = ""
  url                = "jdbc:postgresql://postgres-db1.${var.namespace}.svc.cluster.local:5432/mydb"
  # delegate_selectors = ["harness-delegate"]
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
  org_id    = "default"  
  project_id = var.project_name
  depends_on = [
    harness_platform_project.project,
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
  org_id    = "default"  
  project_id = var.project_name
  depends_on = [
    harness_platform_secret_text.inline2,
  ]
  description        = ""
  url                = "jdbc:postgresql://postgres-db2.${var.namespace}.svc.cluster.local:5432/mydb"
  # delegate_selectors = ["harness-delegate"]
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
  org_id    = "default"  
  project_id = var.project_name
  depends_on = [
    harness_platform_project.project,
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
  org_id    = "default"  
  project_id = var.project_name
  depends_on = [
    harness_platform_secret_text.inline3,
  ]
  description        = ""
  url                = "jdbc:postgresql://postgres-db3.${var.namespace}.svc.cluster.local:5432/mydb"
  # delegate_selectors = ["harness-delegate"]
  credentials {
    auth_type = "UsernamePassword"
    username_password {
      username     = "admin"
      password_ref = "db3"
    }
  }
}

resource "harness_platform_repo" "repo" {
  identifier     = "db_changes"
  org_id    = "default"  
  project_id = var.project_name
  depends_on = [
    harness_platform_project.project,
  ]
  default_branch = "main"
  description    = ""
  source {
    repo = "chrisjws-harness/dbd-scaffold"
    type = "github"
  }
}

resource "harness_platform_connector_git" "test" {
  identifier  = "hcr"
  name        = "hcr"
  org_id    = "default"  
  project_id = var.project_name
  description = ""
  depends_on = [
    harness_platform_secret_text.pl_key,
  ]
  url                = "https://git.harness.io/ifEKEGuIQQKy2ltl3Epatg/default/${var.project_name}/"
  connection_type    = "Account"
  credentials {
    http {
      username     = "chris.storz@harness.io"
      password_ref = "key"
    }
  }
}

resource "harness_platform_db_schema" "db1" {
  identifier = "db1"
  org_id     = "default"
  project_id = var.project_name
  depends_on = [
    harness_platform_connector_git.test,
  ] 
  name       = "DB"
  schema_source {
    connector    = "hcr"
    repo         = "db_changes.git"
    location     = "changelog.yaml"
  }
}

resource "harness_platform_db_instance" "db1" {
  identifier  = "db1"
  org_id     = "default"
  project_id = var.project_name
  name        = "DB1"
  depends_on = [
    harness_platform_db_schema.db1,
  ] 
  schema      = "db1"
  branch      = "main"
  connector   = "db1"
}

resource "harness_platform_db_instance" "db2" {
  identifier  = "db2"
  org_id     = "default"
  project_id = var.project_name
  name        = "DB2"
  depends_on = [
    harness_platform_db_schema.db1,
  ] 
  schema      = "db1"
  branch      = "main"
  connector   = "db2"
}

resource "harness_platform_db_instance" "db3" {
  identifier  = "db3"
  org_id     = "default"
  project_id = var.project_name
  name        = "DB3"
  depends_on = [
    harness_platform_db_schema.db1,
  ] 
  schema      = "db1"
  branch      = "main"
  connector   = "db3"
}
