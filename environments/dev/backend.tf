# -----------------------------
# Terraform backend config
# -----------------------------
terraform {
  backend "s3" {
    bucket         = "{var.project_name}-${var.env}-bucket"
    key            = "terraform/state/terraform.tfstate"
    dynamodb_table = "${var.project_name}-${var.env}-terraform-state-lock"
    encrypt        = true
  }
}