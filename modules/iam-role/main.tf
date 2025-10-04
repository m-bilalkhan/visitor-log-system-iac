#----------------------
# Data Source AWS Caller Identity
#----------------------
data "aws_caller_identity" "current" {}

# ----------------------
# IAM Role for EC2
# ----------------------
resource "aws_iam_role" "ec2_user" {
  name = "${var.project_name}-${var.env}-EC2-User"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.env}-EC2-User"
    Env  = var.env
  }
}

# ----------------------
# Custom IAM Policy for EC2
# ----------------------
resource "aws_iam_policy" "custom_ec2_readonly" {
  name        = "${var.project_name}-${var.env}-EC2-ReadOnly"
  # description = "Custom policy with ECR ReadOnly + SSM read-only + SecretsManager read-only"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR ReadOnly
      {
        Effect   = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeImageScanFindings"
        ]
        Resource = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}/*"
      },
      # SSM ReadOnly (Parameter Store)
      {
        Effect   = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.env}/*"
      },
      # RDS ReadOnly
      {
        Effect   = "Allow"
        Action = [
          "rds-db:connect",
          "rds:DescribeDBInstances"
        ]
        Resource = "arn:aws:rds:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.db_instance_resource_id}/db_user"
      },
    ]
  })
}

# ----------------------
# Create Instance Profile
# ----------------------
resource "aws_iam_instance_profile" "this" {
  name = "${var.project_name}-${var.env}-EC2-Instance-Profile"
  role = aws_iam_role.ec2_user.name
}