# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
# Doc: https://developer.hashicorp.com/terraform/language/values/locals

resource "aws_launch_template" "template" {
  count = var.main_resource_count == true ? 1 : 0
  name  = var.name

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance_profile.arn
  }
  # Workaround: https://stackoverflow.com/questions/76493065/using-the-resulting-ami-from-an-image-builder-recipe-using-terraform
  image_id = tolist(aws_imagebuilder_image.image.output_resources[0].amis)[0].image


  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.micro"

  key_name = aws_key_pair.keypair.key_name

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow_tcp.id]
  }
  # security_group_names = ["${aws_security_group.allow_tcp.id}"]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.name}"
      Envrionment = "main"
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda" # xvda OR sda1 = Root directory

    ebs {
      delete_on_termination = true
      volume_size           = 16
    }
  }

  user_data = filebase64("${local.folder_path}/userdata-main.sh")

  lifecycle {
    ignore_changes = all # Ignore changes
  }
}
