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
  description = "GitHub repo for DB changelogs (org/repo format)"
  type        = string
  default     = "alexsoto-harness/dbdo-sample"
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