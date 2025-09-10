# ----------------------
# Security Group For Load Balancer
# ----------------------
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-${var.env}-alb-sg"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.env}-alb-sg"
    Env = var.env
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_alb_all_outbound_egress" {
  security_group_id = aws_security_group.alb_sg.id
  description = "Allow all outbound traffic"
  ip_protocol       = "-1"        # All protocols
  cidr_ipv4         = "0.0.0.0/0" # Allow all outbound traffic
  tags = {
    Name        = "${var.project_name}-${var.env}-alb-sg-egress"
    Env = var.env
  }
}

resource "aws_vpc_security_group_ingress_rule" "example" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all inbound traffic"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
  tags = {
    Name        = "${var.project_name}-${var.env}-alb-sg-ingress"
    Env = var.env
  }
}

# ----------------------
# Security Group For WEB Application
# ----------------------
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-${var.env}-web-sg"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.env}-web-sg"
    Env = var.env
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_web_all_outbound_egress" {
  security_group_id = aws_security_group.web_sg.id
  description = "Allow all outbound traffic"
  ip_protocol       = "-1"        # All protocols
  cidr_ipv4         = "0.0.0.0/0" # Allow all outbound traffic
  tags = {
    Name        = "${var.project_name}-${var.env}-web-sg-egress"
    Env = var.env
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_from_alb" {
  security_group_id = aws_security_group.web_sg.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  description = "Allow all inbound traffic on port 80 to the load balancer"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
  tags = {
    Name        = "${var.project_name}-${var.env}-web-sg-ingress"
    Env = var.env
  }
}

# ----------------------
# Security Group For Database
# ----------------------
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-${var.env}-db-sg"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.env}-db-sg"
    Env = var.env
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_postgres_from_web" {
  security_group_id = aws_security_group.db_sg.id
  description = "Allow inbound traffic on port 5432 from web application"
  from_port   = 5432
  ip_protocol = "tcp"
  to_port     = 5432
  referenced_security_group_id = aws_security_group.web_sg.id
  tags = {
    Name        = "${var.project_name}-${var.env}-db-sg-ingress"
    Env = var.env
  } 
}