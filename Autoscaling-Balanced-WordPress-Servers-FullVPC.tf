

resource "aws_vpc" "cloudproject_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "CloudProjectVer2VPC"
  }
}

resource "aws_subnet" "cloudproject_subnet_a" {
  vpc_id            = aws_vpc.cloudproject_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "CloudProjectVer2SubnetA"
  }
}

resource "aws_subnet" "cloudproject_subnet_b" {
  vpc_id            = aws_vpc.cloudproject_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "CloudProjectVer2SubnetB"
  }
}

resource "aws_internet_gateway" "cloudproject_igw" {
  vpc_id = aws_vpc.cloudproject_vpc.id

  tags = {
    Name = "CloudProjectVer2IGW"
  }
}

resource "aws_route_table" "cloudproject_route_table" {
  vpc_id = aws_vpc.cloudproject_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudproject_igw.id
  }

  tags = {
    Name = "CloudProjectVer2RouteTable"
  }
}

resource "aws_route_table_association" "cloudproject_rta" {
  subnet_id      = aws_subnet.cloudproject_subnet_a.id
  route_table_id = aws_route_table.cloudproject_route_table.id
}

resource "aws_route_table_association" "cloudproject_rtb" {
  subnet_id      = aws_subnet.cloudproject_subnet_b.id
  route_table_id = aws_route_table.cloudproject_route_table.id
}

resource "aws_security_group" "cloudproject_sg" {
  vpc_id = aws_vpc.cloudproject_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CloudProjectVer2SG"
  }
}

resource "aws_launch_configuration" "cloudproject_lc" {
  image_id        = "ami-0aff18ec83b712f05" # Specify your Ubuntu AMI ID here
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.cloudproject_sg.id]
  key_name        = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              rm -f /var/www/html/index.html
              # Upload your website files to /var/www/html here
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "cloudproject_asg" {
  launch_configuration = aws_launch_configuration.cloudproject_lc.id
  min_size             = 2
  desired_capacity     = 3
  max_size             = 5
  vpc_zone_identifier  = [aws_subnet.cloudproject_subnet_a.id, aws_subnet.cloudproject_subnet_b.id]
  target_group_arns    = [aws_lb_target_group.cloudproject_target_group.arn]
  health_check_type    = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "CloudProjectVer2Server"
    propagate_at_launch = true
  }

  depends_on = [aws_launch_configuration.cloudproject_lc]
}

resource "aws_lb" "cloudproject_lb" {
  name               = "${var.project_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cloudproject_sg.id]
  subnets            = [aws_subnet.cloudproject_subnet_a.id, aws_subnet.cloudproject_subnet_b.id]

  tags = {
    Name = "${var.project_name}-lb"
  }
}

resource "aws_lb_target_group" "cloudproject_target_group" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cloudproject_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  depends_on = [aws_lb.cloudproject_lb]
}

resource "aws_lb_listener" "cloudproject_listener" {
  load_balancer_arn = aws_lb.cloudproject_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cloudproject_target_group.arn
  }
}

resource "aws_autoscaling_policy" "cloudproject_scale_up_policy" {
  name                   = "cloudproject-scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.cloudproject_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cloudproject_cpu_alarm" {
  alarm_name                = "cpu_high"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 50
  alarm_description         = "This metric monitors EC2 CPU utilization"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cloudproject_asg.name
  }
  alarm_actions             = [aws_autoscaling_policy.cloudproject_scale_up_policy.arn]

  depends_on = [aws_autoscaling_group.cloudproject_asg]
}

variable "key_name" {
  description = "Name of an existing EC2 KeyPair to enable SSH access to the instances"
  type        = string
}

variable "project_name" {
  description = "Project name to be used as a prefix for resources"
  type        = string
  default     = "cloudproject"
}
