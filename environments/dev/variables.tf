variable "region" {
    description = "The AWS region to create resources in."
    type        = string
}
variable "env" {
    description = "The environment to deploy (e.g., dev, staging, prod)."
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
variable "project_name" { default = "Visitor-Log-System" }
variable "tg_weights" {
    description = "Target group weights per environment"
    type        = map(map(number))
}
