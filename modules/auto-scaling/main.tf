# ----------------------
# Create Instance Profile
# ----------------------
resource "aws_iam_instance_profile" "this" {
  name = "EC2AccessSSMParameterStoreReadOnly"
  role = "EC2AccessSSMParameterStoreReadOnly"
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

  ebs_optimized = false

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }
  
  image_id = "${var.packer_based_ami_id}"

  vpc_security_group_ids = [ var.security_group_id ]

  user_data = base64encode(
    templatefile("${path.module}/user_data.sh.tpl", {
      region       = var.region
      project_name = var.project_name
      env          = var.env
    })
  )

  instance_initiated_shutdown_behavior = "terminate"

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
resource "aws_autoscaling_group" "asg" {
  name_prefix               = "${var.project_name}-${var.env}-"
  max_size                  = 5
  min_size                  = 1
  vpc_zone_identifier       = var.public_subnet

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "lowest-price"
      spot_instance_pools                      = 2
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.launch_template.id
        version =  "$Latest"
      }
    }
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