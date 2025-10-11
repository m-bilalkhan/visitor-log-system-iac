#----------------------------
# Lambda IAM Role
# ----------------------------
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.env}-rds-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
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
  publicly_accessible = false

  vpc_security_group_ids = [var.db_sg]
  create_db_subnet_group = true
  subnet_ids             = var.private_subnet_ids

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

#----------------------
# Lambda Secret Access Policy
#----------------------
resource "aws_iam_policy" "lambda_secret_access" {
  name = "lambda-secret-access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = module.database.db_instance_master_user_secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secret_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_secret_access.arn
}


# ----------------------------
# Lambda Function
# ----------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_layer_version" "psycopg2" {
  filename            = "${path.module}/psycopg2-layer.zip"
  layer_name          = "psycopg2-layer"
  compatible_runtimes = ["python3.12"]
  description         = "psycopg2-binary compiled for Amazon Linux 2 (Python 3.12)"

  source_code_hash = filebase64sha256("${path.module}/psycopg2-layer.zip")
}

resource "aws_lambda_function" "bootstrap" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "${var.project_name}-${var.env}-rds-configurer"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  timeout          = 300
  publish          = true

  layers = [
    aws_lambda_layer_version.psycopg2.arn
  ]

  environment {
    variables = {
      DB_SECRET_ARN = module.database.db_instance_master_user_secret_arn
      DB_NAME       = format("%s_db", replace(var.project_name, "-", ""))
      DB_PORT       = "5432"
      DB_HOST       = module.database.db_instance_address
      DB_ROLE_NAME  = var.iam_role_name
      DB_USERNAME   = "root"
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [ var.lambda_sg ]
  }
}

# ----------------------------
# Trigger Lambda (runs once)
# ----------------------------
resource "aws_lambda_invocation" "bootstrap_run" {
  function_name = aws_lambda_function.bootstrap.function_name
  input         = jsonencode({})
}