# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/imagebuilder_image_recipe

resource "aws_imagebuilder_image_recipe" "recipe" {
  name              = var.name
  parent_image      = var.parent_image
  version           = "1.0.0"
  working_directory = "/home/${var.image_username}"

  /*user_data_base64 = base64encode(<<EOF
  #!/bin/bash

  EOF
  )*/


  /*block_device_mapping {
    device_name = "/dev/xvdb"
    ebs {
      delete_on_termination = true
      volume_size           = 8
      volume_type           = "gp2"
    }
  }
*/
  component {
    component_arn = aws_imagebuilder_component.codedeploy-agent.arn
  }
  component {
    component_arn = "arn:aws:imagebuilder:${var.region}:aws:component/amazon-cloudwatch-agent-linux/1.0.1/1"
  }
  component {
    component_arn = "arn:aws:imagebuilder:${var.region}:aws:component/simple-boot-test-linux/1.0.0/1"
  }
  component {
    component_arn = aws_imagebuilder_component.docker.arn #"arn:aws:imagebuilder:us-east-1:aws:component/docker-ce-linux/1.0.0/1"
  }
  component {
    component_arn = aws_imagebuilder_component.nodejs.arn
  }
  component {
    component_arn = aws_imagebuilder_component.nginx.arn
  }
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      component, # Ignore changes
    ]
  }
}
