#----------------------
# Data Source AWS Caller Identity
#----------------------
data "aws_caller_identity" "current" {}

# ----------------------
# IAM Role for EC2
# ----------------------
resource "aws_iam_role" "ec2_user" {
  name = "${var.project_name}-${var.env}-ec2-user"
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
    Name = "${var.project_name}-${var.env}-ec2-user"
    Env  = var.env
  }
}

# ----------------------
# Custom IAM Policy for EC2
# ----------------------
resource "aws_iam_policy" "custom_ec2_readonly" {
  name        = "${var.project_name}-${var.env}-ec2-readonly"
  # description = "Custom policy with ECR ReadOnly + SSM read-only + SecretsManager read-only"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR Auth
      {
        Effect   = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:DescribeRepositories",
          "ecr:DescribeRegistry"
        ]
        Resource = "*"
      },
      # ECR ReadOnly
      {
        Effect   = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
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
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*"
      },
      # RDS DB ReadOnly
      {
        Effect   = "Allow"
        Action = [
          "rds:DescribeDBInstances"
        ]
        Resource = "arn:aws:rds:${var.region}:${data.aws_caller_identity.current.account_id}:db:*"
      },
      # RDS IAM AUTH
      {
        Effect   = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.db_instance_resource_id}/${aws_iam_role.ec2_user.name}"
      },
    ]
  })
}

# ----------------------
# Attach Custom IAM Policy to Role
# ----------------------
resource "aws_iam_role_policy_attachment" "attach_custom_ec2_readonly" {
  role       = aws_iam_role.ec2_user.name
  policy_arn = aws_iam_policy.custom_ec2_readonly.arn
}

# ----------------------
# Create Instance Profile
# ----------------------
resource "aws_iam_instance_profile" "this" {
  name = "${var.project_name}-${var.env}-ec2-instance-profile"
  role = aws_iam_role.ec2_user.name
}