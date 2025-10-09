variable "iam_role_name" { type = string }
variable "env" { default = "dev" }
variable "project_name" { default = "visitor-log-system" }
variable "region" { type = string }
variable "db_instance_resource_id" { type = string }