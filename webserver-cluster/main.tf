# ------------------------------------
# ALB
# ------------------------------------
resource "aws_lb" "alb" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids

  tags = {
    Name = "${var.project}-alb"
  }
}

# ------------------------------------
# リスナー　80番ポートHTTPを開く
# ------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  # デフォルトではシンプルな404を返す
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# ------------------------------------
# リスナールール
# ------------------------------------
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

# ------------------------------------
# ターゲットグループ
# ------------------------------------
resource "aws_lb_target_group" "asg" {
  name     = "${var.project}-asg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project}-asg"
  }
}

# ------------------------------------
# Auto Scaling Group
# ------------------------------------
resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "aws_launch_configuration" "as" {
  name            = "${var.project}-as-${random_string.suffix.result}"
  image_id        = "ami-0ab3794db9457b60a"
  instance_type   = var.instance_type
  security_groups = var.security_group_ids
  key_name        = var.key_pair_name

  user_data = <<-EOF
  #!/bin/bash
  # Install Apache
  yum update -y
  yum install -y httpd

  systemctl start httpd
  systemctl enable httpd

  echo "Hello, World" | sudo tee /var/www/html/index.html
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.as.name
  vpc_zone_identifier  = var.subnet_ids

  target_group_arns = var.target_group_arns
  health_check_type = "ELB"

  desired_capacity = 2
  min_size         = 1
  max_size         = 2
  tag {
    key                 = "Name"
    value               = "${var.project}-asg"
    propagate_at_launch = true
  }
}

# ------------------------------------
# key pair
# ------------------------------------
resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh_key"
  public_key = file("./.ssh/ec2keypair.pub")
}

# ------------------------------------
# ALB用セキュリティグループ
# ------------------------------------
resource "aws_security_group" "alb_sg" {
  name   = "${var.project}-alb-sg"
  vpc_id = var.vpc_id

  tags = {
    Name    = "${var.project}-alb-sg"
    Project = var.project
  }
}

resource "aws_security_group_rule" "alb_in_http" {
  security_group_id = aws_security_group.alb_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_out_http" {
  security_group_id        = aws_security_group.alb_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.asg_sg.id
}

# ------------------------------------
# ASG用セキュリティグループ
# ------------------------------------
resource "aws_security_group" "asg_sg" {
  name   = "${var.project}-asg-sg"
  vpc_id = var.vpc_id

  tags = {
    Name    = "${var.project}-asg-sg"
    Project = var.project
  }
}

resource "aws_security_group_rule" "asg_in_http" {
  security_group_id        = aws_security_group.asg_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "asg_in_ssh" {
  security_group_id = aws_security_group.asg_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["153.216.113.64/32"]
}

resource "aws_security_group_rule" "asg_out_all" {
  security_group_id = aws_security_group.asg_sg.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}
