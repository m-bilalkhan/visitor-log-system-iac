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
  source          = "../../modules/networking"
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
  source = "../../modules/security-groups"
  env    = var.env
  vpc_id = module.networking.vpc_id
}

# ----------------------
# S3 Module
# ----------------------
module "s3" {
  source = "../../modules/s3"
  env    = var.env
}

# ----------------------
# Load Balancer Module
# ----------------------
module "load_balancer" {
  source            = "../../modules/load-balancer"
  env               = var.env
  vpc_id            = module.networking.vpc_id
  security_group_id = module.security_groups.aws_alb_sg_id
  s3_bucket_id      = module.s3.s3_bucket_id
  tg_weights        = var.tg_weights
}

# ----------------------
# Database Module
# ----------------------
module "database" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.12.0"

  identifier = "${var.project_name}-${var.env}-db"

  engine               = "postgres"
  engine_version       = "15.5"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 35

  db_name  = "${var.project_name}-db"
  username = "root"
  password = "password" # best: use SSM or Secrets Manager
  port     = 5432

  multi_az            = false
  publicly_accessible = false

  vpc_security_group_ids = [module.security_groups.aws_db_sg_id]
  create_db_subnet_group = true
  subnet_ids             = module.networking.private_subnets

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-${var.env}-DB"
    Env  = var.env
  }
}

# ----------------------
# Route 53 Module
# ----------------------
module "route53" {
  source                = "../../modules/route53"
  env                   = var.env
  project_name          = var.project_name
  aws_route53_zone_name = var.aws_route53_zone_name
  region                = var.region
  alb_arn               = module.load_balancer.alb_arn
}