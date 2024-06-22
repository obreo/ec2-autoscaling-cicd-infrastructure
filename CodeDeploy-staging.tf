# This is used to defiine green/blue deployment for EC2 autoscaling groups using codedeploy. 
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group

resource "aws_codedeploy_app" "staging" {
  count = var.staging_resource_count == true ? 1 : 0
  name  = "${var.name}-staging"
}

resource "aws_codedeploy_deployment_group" "staging" {
  count    = var.staging_resource_count == true ? 1 : 0
  app_name = aws_codedeploy_app.staging[count.index].name
  # Application deployment method to instances - whether gradually or all at once
  deployment_group_name = "${var.name}-staging"
  service_role_arn      = aws_iam_role.codeDeploy_role.arn
  autoscaling_groups    = [aws_autoscaling_group.staging[count.index].id]

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }

    terminate_blue_instances_on_deployment_success {
      #action = "KEEP_ALIVE"
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }
  }


  # Traffic shift from blue to green method
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.blue-staging[count.index].name
    }
  }
  lifecycle {
    ignore_changes = [
      autoscaling_groups
    ]
  }
}
