resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.env}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "test-lb"
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.env}-lb"
    Env  = var.env
  }
}