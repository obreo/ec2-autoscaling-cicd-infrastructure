# ALB
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "load_balancer" {
  name               = "${var.name}-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.load_balancer.id}"]
  subnets            = ["${aws_subnet.public-primary-instance.id}", "${aws_subnet.public-secondary-instance.id}"]

  enable_deletion_protection = false

  tags = {
    Project = "${var.name}"

  }
}

# Target Group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
# Main
resource "aws_lb_target_group" "blue" {
  name                 = "${var.name}-blue"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.vpc.id
  deregistration_delay = 30 # seconds
  health_check {
    enabled             = true
    port                = 80
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200,202,302"
    path                = "/"
  }

  stickiness {
    enabled         = true
    cookie_duration = 86400 # Seconds = 1 Day
    type            = "lb_cookie"
  }
}

# Staging
resource "aws_lb_target_group" "blue-staging" {
  count                = var.staging_resource_count == true ? 1 : 0
  name                 = "${var.name}-blue-staging"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.vpc.id
  deregistration_delay = 30 # seconds
  health_check {
    enabled             = true
    port                = 80
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200,202,302"
    path                = "/"
  }

  stickiness {
    enabled         = true
    cookie_duration = 86400 # Seconds = 1 Day
    type            = "lb_cookie"
  }
}

# Listener & Listener rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "default" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = var.HTTPS == true && var.shared_loadbalancer == true ? "443" : "80" # HTTP 80 used, for HTTPS 443 port there must be a certificate defined.
  protocol          = var.HTTPS == true && var.shared_loadbalancer == true ? "HTTPS" : "HTTP"
  # Doc: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies
  ssl_policy      = var.HTTPS == true ? "ELBSecurityPolicy-TLS13-1-2-2021-06" : null
  certificate_arn = var.HTTPS == true ? "${var.HTTPS_Certificate_ARN}" : null


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

# Listener rule: main
resource "aws_lb_listener_rule" "main" {
  count        = var.shared_loadbalancer == true ? 1 : 0
  listener_arn = aws_lb_listener.default.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    host_header {
      values = [var.HTTPS == true ? "${var.production_url}" : null]
    }
  }
}

# Listener rule: staging
resource "aws_lb_listener_rule" "staging" {
  count        = var.staging_resource_count == true && var.shared_loadbalancer == true ? 1 : 0
  listener_arn = aws_lb_listener.default.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue-staging[0].arn
  }

  condition {
    host_header {
      values = [var.HTTPS == true ? "${var.staging_url}" : null]
    }
  }
}