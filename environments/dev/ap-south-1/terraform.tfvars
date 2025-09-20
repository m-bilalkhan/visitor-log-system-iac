env = "dev"
vpc_cidr = "1.0.0.0/16"
public_subnet_cidrs = ["1.0.1.0/24", "1.0.2.0/24"]
private_subnet_cidrs = ["1.0.101.0/24", "1.0.102.0/24"]
availability_zones = ["ap-south-1a", "ap-south-1b"]
tg_weights = {
  "dev" = {
    "dev" = 100
  }
}
aws_route53_zone_name = "bilalcloudventures.com"
project_name = "visitor-log-system"
instance_type = "t3.micro"