output "aws_alb_sg_id" {
  description = "The ID of the AWS application load balancer security group"
  value       = aws_security_group.alb_sg.id
}

output "aws_db_sg_id" {
  description = "The ID of the DB security group"
  value       = aws_security_group.db_sg.id
}

output "aws_web_sg_id" {
  description = "The ID of the web application security group"
  value       = aws_security_group.web_sg.id
}

output "aws_lambda_sg_id" {
  description = "The ID of the lambda security group"
  value       = aws_security_group.lambda_sg.id
}

output "aws_vpcep_sg_id" {
  description = "The ID of the vpc endpoint security group"
  value       = aws_security_group.vpcep_sg.id
}