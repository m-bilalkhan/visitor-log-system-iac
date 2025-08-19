variable "vpc_cidr" {}
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "azs" { type = list(string) }
variable "env" { default = "dev" }
variable "project_name" { default = "3-TIER-WEB-APP" }
