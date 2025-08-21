output "aws_alb_sg_id" {
  description = "The ID of the AWS application load balancer security group"
  value       = aws_security_group.alb_sg.id
}

output "aws_web_sg_id" {
  description = "The ID of the AWS application load balancer security group"
  value       = aws_security_group.web_sg.id
}