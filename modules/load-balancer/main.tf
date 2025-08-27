# ----------------------
# Target Group
# ----------------------
locals {
  tg_names = var.env == "prod" ? ["-blue-", "-green-"] : ["-"]
}
resource "aws_lb_target_group" "test" {
  for_each = toset(local.tg_names)
  #Default target type is instance
  name     = "${var.project_name}-${var.env}${each.key}lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}
# ----------------------
# Bucket for Load Balancer Logs
# ----------------------
//maybe create it here or one big s3 bucket in both env for this project
# ----------------------
# Load Balancer
# ----------------------
resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.env}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "${var.env}-lb-logs"
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.env}-lb"
    Env  = var.env
  }
}