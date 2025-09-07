# -----------------------------
# S3 bucket
# -----------------------------
resource "aws_s3_bucket" "this" {
  bucket = "${var.project_name}-${var.env}-bucket"
  tags = {
    Name = "${var.project_name}-${var.env}-bucket"
    Env  = var.env
  }
}

#-----------------------------
# s3 bucket versioning
#-----------------------------
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------
# Server-side encryption
#-----------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
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
# DynamoDB table for state locking
# -----------------------------
resource "aws_dynamodb_table" "tf_lock" {
  name         = "${var.project_name}-${var.env}-terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-${var.env}-terraform-state-lock"
    Env  = var.env
  }
}