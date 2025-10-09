variable "project_name" { default = "visitor-log-system" }
variable "env" { default = "dev" }
variable "vpc_security_group_ids" { type = list(string) }
variable "subnet_ids" { type = list(string) }
variable "iam_role_name" { type = string }
variable "lambda_sg" { type = string }
variable "db_sg" { type = string }