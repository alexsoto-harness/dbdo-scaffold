variable "project_name" {
  description = "The id (single string, no special characters) of the user"
  type        = string
  default     = "test"
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