resource "harness_platform_project" "project" {  
    name      = var.project_name 
    identifier = var.project_name  
    org_id    = "default"  
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
  name           = "DB Changes"
  org_id    = "default"  
  project_id = var.project_name
  depends_on = [
    harness_platform_project.project,
  ]
  default_branch = "main"
  description    = ""
  source {
    repo = "octocat/hello-worId"
    type = "github"
  }
}
