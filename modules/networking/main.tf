# ----------------------
# VPC
# ----------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.env}-vpc"
    Env  = var.env
  }
}

# ----------------------
# Public Subnets
# ----------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.env}-public-${count.index + 1}"
    Tier = "public"
    Env  = var.env
  }
}

# ----------------------
# Private Subnets
# ----------------------
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-${var.env}-private-${count.index + 1}"
    Tier = "private"
    Env  = var.env
  }
}

# ----------------------
# Internet Gateway
# ----------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-${var.env}-igw"
    Env  = var.env
  }
}

# ----------------------
# Route Tables
# ----------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-${var.env}-public-rt"
    Env  = var.env
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ----------------------
# Security Groups
# ----------------------
resource "aws_security_group" "this" {
  name        = "${var.project_name}-${var.env}-sg"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name        = "${var.project_name}-${var.env}-sg"
    Environment = var.env
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_egress" {
  security_group_id = aws_security_group.this.id
  description = "Allow all outbound traffic"
  ip_protocol       = "-1"        # All protocols
  cidr_ipv4         = "0.0.0.0/0" # Allow all outbound traffic
  tags = {
    Name        = "${var.project_name}-${var.env}-sg-egress"
    Environment = var.env
  }
}

resource "aws_vpc_security_group_ingress_rule" "example" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4   = "0.0.0.0/0" # Allow all inbound traffic To
  description = "Allow all inbound traffic"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}