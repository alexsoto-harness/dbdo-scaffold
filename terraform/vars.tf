variable "project_name" {
  description = "The id (single string, no special characters) of the project"
  type        = string
  default     = "Reference_Architecture"
}

variable "create_project" {
  description = "Set to false to use an existing project instead of creating one"
  type        = bool
  default     = false
}

variable "namespace" {
  description = "kubernetes namespace the dbs are running in"
  type        = string
  default     = "db-lab"
}

variable "organization" {
  description = "Organization for the workshop"
  type        = string
  default     = "default"
}

variable "create_org" {
  description = "Set to false to use an existing org instead of creating one"
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "GitHub repo for DB changelogs. Use just the repo name (e.g. 'dbdo-sample') if your GitHub connector already includes the org/account URL. Use 'org/repo' format only if your connector points to github.com with no org prefix."
  type        = string
  default     = "dbdo-sample"
}

variable "github_connector" {
  description = "Identifier of the GitHub connector in Harness"
  type        = string
  default     = "Harness_Github"
}

variable "github_connector_scope" {
  description = "Scope of the GitHub connector: account, org, or project"
  type        = string
  default     = "account"

  validation {
    condition     = contains(["account", "org", "project"], var.github_connector_scope)
    error_message = "github_connector_scope must be one of: account, org, project."
  }
}

variable "delegate_selector" {
  description = "Harness delegate selector for JDBC connector routing"
  type        = string
  default     = "tr-pov-helm-delegate"
}

variable "k8s_connector" {
  description = "Identifier of the Kubernetes connector in Harness (used in lab step groups for containerized execution)"
  type        = string
  default     = "harnesstrcluster"
}

variable "k8s_connector_scope" {
  description = "Scope of the Kubernetes connector: account, org, or project"
  type        = string
  default     = "account"

  validation {
    condition     = contains(["account", "org", "project"], var.k8s_connector_scope)
    error_message = "k8s_connector_scope must be one of: account, org, project."
  }
}

variable "migration_type" {
  description = "Database migration tool: liquibase or flyway"
  type        = string
  default     = "liquibase"

  validation {
    condition     = contains(["liquibase", "flyway"], var.migration_type)
    error_message = "migration_type must be one of: liquibase, flyway."
  }
}