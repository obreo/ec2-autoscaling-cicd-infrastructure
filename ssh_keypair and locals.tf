resource "aws_key_pair" "keypair" {
  key_name   = var.name
  public_key = var.keypair
}

locals {
  folder_path = "./scripts" # Update this with the path to your folder
}