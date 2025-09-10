# ----------------------
# Subnets
# ----------------------
data "aws_subnets" "public" {
  filter {
    name   = "tag:Tier"
    values = ["public"]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# ----------------------
# Target Group
# ----------------------
locals {
  tg_names = var.env == "prod" ? ["blue", "green"] : ["dev"]
}
resource "aws_lb_target_group" "lb_tg" {
  for_each = toset(local.tg_names)
  #Default target type is instance
  name     = "${var.project_name}-${each.key}-lb-tg"
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
# Load Balancer
# ----------------------
resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.env}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            =  tolist(data.aws_subnets.public.ids)

  enable_deletion_protection = false

  access_logs {
    bucket  = var.s3_bucket_id
    prefix  = "logs/"+ var.region +"/load-balancer"
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.env}-lb"
    Env  = var.env
  }
}

# ----------------------
# Listners
# ----------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      dynamic "target_group" {
        for_each = aws_lb_target_group.lb_tg
        content {
          arn    = target_group.value.arn
          weight = lookup(
            lookup(var.tg_weights, var.env, {}),
            target_group.key,
            100
          )
        }
      }
    }
  }
}