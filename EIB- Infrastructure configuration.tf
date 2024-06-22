# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/imagebuilder_infrastructure_configuration
resource "aws_imagebuilder_infrastructure_configuration" "config" {
  description                   = "example description"
  instance_profile_name         = aws_iam_instance_profile.Ec2ImageBuilderIAMRole.name
  key_pair                      = aws_key_pair.keypair.key_name
  name                          = var.name
  security_group_ids            = [aws_security_group.allow_tcp.id]
  subnet_id                     = aws_subnet.public-primary-instance.id
  terminate_instance_on_failure = true

  logging {
    s3_logs {
      s3_bucket_name = aws_s3_bucket.bucket.bucket
      s3_key_prefix  = "logs"
    }
  }

  tags = {
    Name = "${var.name}"
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      instance_profile_name,
      key_pair,
      security_group_ids,
      subnet_id, # Ignore changes
    ]
  }
}
