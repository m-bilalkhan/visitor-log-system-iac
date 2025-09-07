variable "security_group_id" { type = string }
variable "env" { default = "dev" }
variable "project_name" { default = "Visitor-Log-System" }
variable "vpc_id" { type = string }
variable "s3_bucket_id" { type = string }
variable "tg_weights" {
  description = "Target group weights per environment"
  type        = map(map(number))
  default     = {}
}