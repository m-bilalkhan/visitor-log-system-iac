terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.12.0"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "~>1.26.0"
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
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.12.0"

  identifier = "${lower(var.project_name)}-${var.env}-db"

  engine               = "postgres"
  engine_version       = "15"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 35

  db_name  = format("%s_db", replace(var.project_name, "-", ""))
  username = "root"
  port     = "5432"

  manage_master_user_password_rotation              = true
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(15 days)"

  # Enable IAM auth
  iam_database_authentication_enabled = true

  multi_az            = false
  publicly_accessible = true

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
  env                    = var.env
  project_name           = var.project_name
  region                 = var.region
  db_instance_resource_id = module.database.db_instance_resource_id
}

# PostgreSQL Provider Configuration
#----------------------
# Secret manager to fetch the password
#----------------------
data "aws_secretsmanager_secret_version" "postgres_password" {
  secret_id = module.database.db_instance_master_user_secret_arn
}

provider "postgresql" {
  host            = module.database.db_instance_address
  port            = aws_ssm_parameter.db_port.value
  database        = aws_ssm_parameter.db_name.value
  username        = "root"
  password        = jsondecode(data.aws_secretsmanager_secret_version.postgres_password.secret_string)["password"]
  sslmode         = "require"
  connect_timeout = 15
}

#----------------------
# PostgreSQL Role and Grants
#----------------------
resource "postgresql_role" "this" {
  name     = module.iam_role.iam_role_name
  login    = true
  roles = ["rds_iam"]
  password = null
}

resource postgresql_grant "this" {                                                                                                                                                
  database    = aws_ssm_parameter.db_name.value                                                                                                                                                                   
  role        = postgresql_role.this.name                                                                                                                                                
  schema      = "public"                                                                                                                                                                     
  object_type = "database"                                                                                                                                                                      
  privileges  = ["Create", "Connect", "SELECT", "UPDATE", "INSERT"]                                                                                                                                                              
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