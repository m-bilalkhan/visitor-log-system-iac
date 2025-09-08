variable "env" { default = "dev" }
variable "project_name" { default = "Visitor-Log-System" }
variable "aws_route53_zone_name" {
  description = "The name of the Route 53 hosted zone"
  type        = string
}
variable "region" {
  description = "AWS region"
  type        = string
}
variable "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  type        = string
}