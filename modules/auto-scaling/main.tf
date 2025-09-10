# ----------------------
# Launch Template
# ----------------------
resource "aws_launch_template" "launch_template" {
  name_prefix = "${var.project_name}-${var.env}-"

  credit_specification {
    cpu_credits = "standard"
  }

  disable_api_stop        = true
  disable_api_termination = true

  ebs_optimized = true

  iam_instance_profile {
    name = "EC2AccessSSMParameterStoreReadOnly"
  }
  
  image_id = "${var.packer_based_ami_id}"

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e

              REGION="${var.region}"
              ENV_PATH="/${var.project_name}/${var.env}"

              # Fetch all parameters from SSM Parameter Store
              PARAMS=$(aws ssm get-parameters-by-path \
                --path "$ENV_PATH" \
                --with-decryption \
                --region $REGION \
                --query "Parameters[*].{Name:Name,Value:Value}" \
                --output text)

              # Overwrite /home/ec2-user/.env
              ENV_FILE="/home/ec2-user/.env"
              rm -f $ENV_FILE

              echo "$PARAMS" | while read Name Value; do
                Key=$(basename "$Name")
                echo "${Key^^}=$Value" >> $ENV_FILE
              done

              chown ec2-user:ec2-user $ENV_FILE
              systemctl enable docker-compose-app.service
              systemctl start docker-compose-app.service
              EOF
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