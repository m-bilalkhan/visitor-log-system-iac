# -----------------------------
# Terraform backend config
# -----------------------------
terraform {
  backend "s3" {
    bucket         = "visitor-log-system-dev-bucket"
    key            = "terraform/state/dev/ap-south-1.tfstate"
    use_lockfile   = true
    encrypt        = true
    region         = "ap-south-1"
  }
}