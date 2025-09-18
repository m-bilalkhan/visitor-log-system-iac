# ----------------------
# Create IAM Role for EC2 to access SSM Parameter Store
# ----------------------
resource "aws_iam_role" "ec2_role" {
  name = "EC2AccessSSMParameterStoreReadOnly"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# ----------------------
# Attach Policy to the Role
# ----------------------
resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ----------------------
# Create Instance Profile
# ----------------------
resource "aws_iam_instance_profile" "this" {
  name = "EC2AccessSSMParameterStoreReadOnly"
  role = aws_iam_role.ec2_role.name
}
# ----------------------
# Launch Template
# ----------------------
resource "aws_launch_template" "launch_template" {
  name_prefix = "${var.project_name}-${var.env}-"

  credit_specification {
    cpu_credits = "standard"
  }

  disable_api_termination = false

  ebs_optimized = true

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }
  
  image_id = "${var.packer_based_ami_id}"

  user_data = base64encode(
    templatefile("${path.module}/user_data.sh.tpl", {
      region       = var.region
      project_name = var.project_name
      env          = var.env
    })
  )

  instance_initiated_shutdown_behavior = "terminate"

  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
      max_price                     = "0.01"
      spot_instance_type            = "one-time"
    }
  }

  instance_type = var.instance_type

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-${var.env}-launch-template"
      Env  = var.env
    }
  }
}

# ----------------------
# Auto Scaling Group
# ----------------------
resource "aws_autoscaling_group" "bar" {
  name_prefix               = "${var.project_name}-${var.env}-"
  max_size                  = 5
  min_size                  = 1
  availability_zones        = var.azs
  launch_template {
    id      = aws_launch_template.launch_template.id
  }

  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }
  force_delete              = false
  target_group_arns = var.target_group_arns

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.env}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Env"
    value               = var.env
    propagate_at_launch = true
  }
  
  timeouts {
    delete = "15m"
  }
}