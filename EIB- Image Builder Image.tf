# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/imagebuilder_image_pipeline
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/imagebuilder_image

/*
# Defining pipeline
resource "aws_imagebuilder_image_pipeline" "image" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.config.arn
  name                             = "${var.name}-pipeline"
}
*/

# Getting Image info:
resource "aws_imagebuilder_image" "image" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.config.arn

  lifecycle {
    prevent_destroy = false
  }
}
