# -----------------------------
# S3 bucket
# -----------------------------
data "aws_s3_bucket" "this" {
  bucket = "${var.project_name}-${var.env}-bucket"
}

# -----------------------------
# s3 lifecycle policies
#-----------------------------
resource "aws_s3_bucket_lifecycle_configuration" "name" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "log-loadbalancer-lifecycle-rule"
    status = "Enabled"

    expiration {
      days = 90
    }

    filter {
      prefix = "logs/load-balancer/"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "tfstate-lifecycle-rule"
    status = "Enabled"

    expiration {
      days = 365
    }

    filter {
      prefix = "terraform/state/"
    }

    noncurrent_version_expiration {
      noncurrent_days = 180
    }
  }
}

# -----------------------------
# s3 alb log policy
#-----------------------------
resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}