resource "aws_ecr_repository" "respository" {
  count = var.Docker_Application == true ? 1 : 0

  name                 = var.ecr_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}
