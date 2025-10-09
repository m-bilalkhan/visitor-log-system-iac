terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.12.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ----------------------
# Networking Module
# ----------------------
module "networking" {
  source          = "../../../modules/networking"
  env             = var.env
  vpc_cidr        = var.vpc_cidr
  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs
}

# ----------------------
# Security Groups Module
# ----------------------
module "security_groups" {
  source = "../../../modules/security-groups"
  env    = var.env
  vpc_id = module.networking.vpc_id
}

# ----------------------
# S3 Module
# ----------------------
module "s3" {
  source = "../../../modules/s3"
  env    = var.env
}

# ----------------------
# Load Balancer Module
# ----------------------
module "load_balancer" {
  source            = "../../../modules/load-balancer"
  env               = var.env
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnets
  security_group_id = module.security_groups.aws_alb_sg_id
  s3_bucket_id      = module.s3.s3_bucket_id
  tg_weights        = var.tg_weights
  region            = var.region
}

# ----------------------
# Database Module
# ----------------------
module "database" {
  source  = "../../../modules/rds"
  project_name = var.project_name
  env = var.env
  private_subnet_ids = module.networking.private_subnets
  public_subnet_ids = module.networking.public_subnets
  iam_role_name = var.iam_role_name
  lambda_sg = module.security_groups.aws_lambda_sg_id
  db_sg = module.security_groups.aws_db_sg_id
}

resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.project_name}/${var.env}/db_host"
  type  = "String"
  value = module.database.db_instance_address
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.project_name}/${var.env}/db_name"
  type  = "String"
  value = format("%s_db", replace(var.project_name, "-", ""))
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/${var.project_name}/${var.env}/db_port"
  type  = "String"
  value = 5432
}

# ----------------------
# IAM Role Module 
# ----------------------
module "iam_role" {
  source                 = "../../../modules/iam-role"
  iam_role_name          = var.iam_role_name
  env                    = var.env
  project_name           = var.project_name
  region                 = var.region
  db_instance_resource_id = module.database.db_instance_resource_id
}

# ----------------------
# Auto Scaling Module
# ----------------------
module "auto_scaling" {
  source            = "../../../modules/auto-scaling"
  env               = var.env
  region            = var.region
  project_name      = var.project_name
  public_subnet     = module.networking.public_subnets
  packer_based_ami_id = var.ami_id
  instance_type     =  var.instance_type
  security_group_id = module.security_groups.aws_web_sg_id
  target_group_arns = module.load_balancer.target_group_arns
  iam_instance_profile_name = module.iam_role.instance_profile_name
}

# ----------------------
# Route 53 Module
# ----------------------
module "route53" {
  source                = "../../../modules/route53"
  env                   = var.env
  project_name          = var.project_name
  aws_route53_zone_name = var.aws_route53_zone_name
  region                = var.region
  alb_arn               = module.load_balancer.alb_arn
}