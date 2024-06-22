# Define the content of appspec.yml using Terraform variables
locals {
  before_install = <<EOF
#!/bin/bash
# Before install will set the following:
# Set swap area to allow npm rendering in the EC2 instance of low capacity.
# Call SSM Parameters and store them in root directory.

# Swap Area - To avoid server hang during code run
sudo fallocate -l 1G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab && sudo swapon --show && free -h
-
# Create directory and move to it - just in case not available
#if [ ! -d "/var/webapp" ]; then
#    sudo mkdir -p /var/webapp
#fi

echo directory
cd /var/webapp
pwd

# Stopping running server - For In-Place deployment
#echo 'Stopping npm server'
#while read pid; do kill -9 "$pid"; done < <(ps aux | grep "[n]ext-server" | awk '{print $2}') 2>> /var/log/error.log


EOF
}

# Write the content to  before_install.sh file
resource "local_file" "before_install" {
  count    = var.Docker_Application == true ? 0 : 1
  filename = "scripts/scripts/before_install.sh"
  content  = local.before_install
}
#########################################################################
# Define the content of appspec.yml using Terraform variables
locals {
  after_install = <<EOF
#!/bin/bash
# After Install will do the following:
# Remove the next start module as a workaround to fix npm start error. 
# Install missing modules again with npm i -f
# start the application on isolated session using nohup.... &
# This will allow codedepploy to not get stuck waiting for a command execution to end.

echo 'directory'
cd /var/webapp

echo 'starting Next app:'
rm -rf /var/webapp/node_modules/.bin/next
npm i -f
nohup npm start >/dev/null 2>> /var/log/error.log &

EOF
}

# Write the content to  after_install.sh file
resource "local_file" "after_install" {
  count    = var.Docker_Application == true ? 0 : 1
  filename = "scripts/scripts/after_install.sh"
  content  = local.after_install
}


#######################################################################################################
# This is released for docker applications
#######################################################################################################

# Define the content of appspec.yml using Terraform variables
locals {
  before_install_docker = <<EOF
#!/bin/bash

echo 'Clearing previous builds..'
docker stop $(docker ps -aq)
sleep 5

docker contianer prune -f
sleep 5

docker image prune -f
sleep 5

docker rmi $(docker images -aq) -f
sleep 5

docker volume prune -f

# Pulling image from the ECR registry, make sure the IAM instance profile has credintials to access ECR.
echo 'pulling the new image'
aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com

docker run -d --env-file /var/webapp/.env -p ${var.host_to_container_ports} --name ${var.name} ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_name}:latest
EOF
}

# Write the content to  before_install.sh file
resource "local_file" "before_install_docker" {
  count    = var.Docker_Application == true ? 1 : 0
  filename = "scripts/scripts/before_install.sh"
  content  = local.before_install_docker
}
