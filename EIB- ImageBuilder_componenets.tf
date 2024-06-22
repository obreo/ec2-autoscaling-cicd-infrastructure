# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/imagebuilder_components
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/imagebuilder_component
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/imagebuilder_component
# Doc: https://docs.aws.amazon.com/imagebuilder/latest/userguide/create-component-yaml.html
# CREATE COMPONENTS

## 1. CodeDeploy Agent:
resource "aws_imagebuilder_component" "codedeploy-agent" {
  name        = "codedeploy-agent"
  description = "Installing CodeDeploy Agent"
  platform    = "Linux"
  version     = "1.0.0"
  data = yamlencode({
    phases = [{
      name = "build"
      steps = [
        {
          name   = "Install_chkconfig"
          action = "ExecuteBash"
          inputs = {
            commands = ["sudo yum install -y chkconfig"]
          }
        },
        {
          name   = "CodeDeploy_agent"
          action = "ExecuteBash"
          inputs = {
            commands = [
              "sudo yum update -y",
              "sudo yum install -y ruby wget",
              "cd /home/ec2-user",
              "wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install",
              "chmod +x ./install",
              "sudo ./install auto",
              "sudo service codedeploy-agent start",
              "sudo chkconfig codedeploy-agent on"
            ]
          }
        }
      ]
      },
      {
        name = "validate"
        steps = [
          {
            name   = "CodeDeploy_agent_validation"
            action = "ExecuteBash"
            inputs = {
              commands = ["output=$(systemctl status codedeploy-agent | grep 'Active') && echo '$output'"]
            }
          }
        ]
      }
    ]
    schemaVersion = 1.0
  })

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      data, # Ignore changes
    ]
  }
}


## 2. Docker:
resource "aws_imagebuilder_component" "docker" {
  name        = "Docker"
  description = "Installing Docker"
  platform    = "Linux"
  version     = "1.0.0"
  data = yamlencode({
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "Docker"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "sudo yum install -y docker",
                "sudo systemctl start docker",
                "sudo chkconfig docker on",
                "sudo usermod -a -G docker ec2-user"
              ]
            }
          }
        ]
      }
    ]
    schemaVersion = 1.0
  })

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      data, # Ignore changes
    ]
  }
}

## 3. NodeJS:
resource "aws_imagebuilder_component" "nodejs" {
  name        = "NodeJS"
  description = "Installing NodeJS 20 runtime"
  platform    = "Linux"
  version     = "1.0.0"
  data = yamlencode({
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "nodejs"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -",
                "sudo yum install -y nodejs"
              ]
            }
          }
        ]
      },
      {
        name = "validate"
        steps = [
          {
            name   = "nodejs-validation"
            action = "ExecuteBash"
            inputs = {
              commands = ["node -v && npm -v && whoami"]
            }
          }
        ]
      }
    ]
    schemaVersion = 1.0
  })

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      data, # Ignore changes
    ]
  }
}

## 4. Unzip:
resource "aws_imagebuilder_component" "unzip" {
  name        = "unzip"
  description = "Installing unzip"
  platform    = "Linux"
  version     = "1.0.0"
  data = yamlencode({
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "unzip"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "sudo yum install -y unzip"
              ]
            }
          }
        ]
      },
      {
        name = "validate"
        steps = [
          {
            name   = "unzip_validation"
            action = "ExecuteBash"
            inputs = {
              commands = ["unzip -v"]
            }
          }
        ]
      }
    ]
    schemaVersion = 1.0
  })

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      data, # Ignore changes
    ]
  }
}


## 5. Nginx:
resource "aws_imagebuilder_component" "nginx" {
  name        = "nginx"
  description = "Installing nginx"
  platform    = "Linux"
  version     = "1.0.0"
  data = yamlencode({
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "nginx"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "sudo yum install -y nginx",
                "sudo touch /etc/nginx/conf.d/default.conf",
                <<-EOF
echo 'skipped for other coomands, used for multi commands'
                EOF
                , "sudo chkconfig nginx on",
                "sudo sudo service nginx stop",
                "sudo service nginx start"
              ]
            }
          }
        ]
      },
      {
        name = "validate"
        steps = [
          {
            name   = "nginx_validation"
            action = "ExecuteBash"
            inputs = {
              commands = ["sudo nginx -t"]
            }
          }
        ]
      }
    ]
    schemaVersion = 1.0
  })

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      data, # Ignore changes
    ]
  }
}