# Define the content of appspec.yml using Terraform variables
locals {
  appspec_content = <<EOF
# Doc: https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-files.html
version: 0.0
os: linux
files:
  - source: /
    destination: /var/webapp
file_exists_behavior: OVERWRITE
permissions:
  - object: /var/webapp
    pattern: "**"
    owner: ec2-user
    group: ec2-user
hooks:
  BeforeInstall:
    - location: scripts/before_install.sh
      timeout: 300
      runas: root
  AfterInstall:
    - location: scripts/after_install.sh
      timeout: 300
      runas: root

  EOF
}

# Write the content to appspec.yml file
resource "local_file" "appspec" {
  count    = var.Docker_Application == true ? 0 : 1
  filename = "scripts/appspec.yml"
  content  = local.appspec_content
}

#####################################################################
# This is released if application uses docker image

# Define the content of appspec.yml using Terraform variables
locals {
  appspec_content_docker = <<EOF
  # Doc: https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-files.html
  version: 0.0
  os: linux
  hooks: # Scripts to run (Expanation of purposes is found in the aws doc)
    BeforeInstall:
      # Path of file
      - location: scripts/before_install.sh
        timeout: 300
        runas: ec2-user
  EOF
}

# Write the content to appspec.yml file
resource "local_file" "appspec_docker" {
  count    = var.Docker_Application == true ? 1 : 0
  filename = "scripts/appspec.yml"
  content  = local.appspec_content_docker
}