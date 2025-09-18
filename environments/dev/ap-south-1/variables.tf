variable "region" {
  description = "The AWS region to create resources in."
  type        = string
  default = "ap-south-1"
}
variable "env" {
  description = "The environment to deploy"
  type        = string
  default     = "dev"
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
}
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
}
variable "availability_zones" {
  description = "List of availability zones to use."
  type        = list(string)
}
variable "project_name" { default = "visitor-log-system" }
variable "tg_weights" {
  description = "Target group weights per environment"
  type        = map(map(number))
}
variable "aws_route53_zone_name" {
  description = "The name of the Route 53 hosted zone"
  type        = string
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
}