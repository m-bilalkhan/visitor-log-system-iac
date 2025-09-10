output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}
output "target_group_arns" {
  description = "List of ARNs of the target groups"
  value       = [for tg in aws_lb_target_group.lb_tg : tg.arn]
}