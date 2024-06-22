# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
resource "aws_autoscaling_group" "main" {
  vpc_zone_identifier       = [aws_subnet.public-primary-instance.id, aws_subnet.public-secondary-instance.id]
  desired_capacity          = 1
  max_size                  = 2
  min_size                  = 1
  name                      = "${var.name}-main"
  target_group_arns         = [aws_lb_target_group.blue.arn]
  health_check_grace_period = 300
  #health_check_type         = "ELB"

  launch_template {
    id      = aws_launch_template.template[0].id
    version = "$Latest"
  }

  tag {
    key                 = "application"
    value               = var.name
    propagate_at_launch = true
  }
  tag {
    key                 = "envrionment"
    value               = "main"
    propagate_at_launch = true
  }
  lifecycle {
    ignore_changes = all
  }
}

# Autoscaling Policy
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy
resource "aws_autoscaling_policy" "main" {
  autoscaling_group_name = aws_autoscaling_group.main.name
  name                   = "${var.name}-main-asg-policy"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    target_value = 80
    /*customized_metric_specification {
      metrics {
        label = "Get the queue size (the number of messages waiting to be processed)"
        id    = "m1"
        metric_stat {
          metric {
            namespace   = "AWS/SQS"
            metric_name = "ApproximateNumberOfMessagesVisible"
            dimensions {
              name  = "QueueName"
              value = "my-queue"
            }
          }
          stat = "Sum"
        }
        return_data = false
      }
      metrics {
        label = "Get the group size (the number of InService instances)"
        id    = "m2"
        metric_stat {
          metric {
            namespace   = "AWS/AutoScaling"
            metric_name = "GroupInServiceInstances"
            dimensions {
              name  = "AutoScalingGroupName"
              value = "my-asg"
            }
          }
          stat = "Average"
        }
        return_data = false
      }
      metrics {
        label       = "Calculate the backlog per instance"
        id          = "e1"
        expression  = "m1 / m2"
        return_data = true
      }
    }*/
  }
  lifecycle {
    ignore_changes = all
  }
}
