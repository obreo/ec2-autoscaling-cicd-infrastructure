# General
variable "account_id" {
  description = "AWS Account number"
  type        = string
  #default     = ""
  sensitive   = true
}
variable "region" {
  description = ""
  type        = string
  default     = ""
  sensitive   = false
}

# Project settings
variable "name" {
  description = "Application name"
  type        = string
  default     = ""
  sensitive   = false
}

# EC2 Image builder settings
variable "image_username" {
  description = "Username of linux OS to be built in the AMI"
  type        = string
  default     = "ec2-user" # Default user in Amazon Linux
  sensitive   = false
}
variable "parent_image" {
  description = "Base Image fo building custom AMI"
  type        = string
  default     = "ami-08a0d1e16fc3f61ea" # AL2023 Stockholm: ami-0d3a2960fcac852bc US East: ami-08a0d1e16fc3f61ea
  sensitive   = false
}

# EC2
variable "keypair" {
  description = "SSH public key for EC2 instances"
  type        = string
  default     = ""
  sensitive   = false
}

# Nginx
variable "application_port" {
  description = "Choose to which port Nginx will redirect traffic"
  type        = string
  default     = "3000"
  sensitive   = false
}

# RDS settings
variable "rds_port" {
  description = "0 value means No rds to be created"
  type        = number
  default     = 0
  sensitive   = false
}

# Docker Container settings
variable "Docker_Application" {
  description = "If the application is based on docker image, then set the value to true"
  type        = bool
  default     = false
  sensitive   = false
}
variable "ecr_name" {
  description = "ECR registry name"
  type        = string
  default     = ""
  sensitive   = false
}
variable "host_to_container_ports" {
  description = "Host to container image ports"
  type        = string
  default     = "80:80"
  sensitive   = false
}


# SSL
variable "HTTPS" {
  description = "Allow HTTPS: True / False"
  type        = bool
  default     = true
  sensitive   = false
}
variable "HTTPS_Certificate_ARN" {
  description = "ACM certificate arn"
  type        = string
  default     = ""
  sensitive   = false
}


# Route53
variable "zone_id" {
  description = "Host Zone ID for the used Domain for shared load balancing | Required if shared load balancer enabled"
  type        = string
  default     = ""
  sensitive   = false
}
variable "production_url" {
  description = "Application Production URL for shared load balancing | Required if shared load balancer enabled"
  type        = string
  default     = ""
  sensitive   = false
}
variable "staging_url" {
  description = "Application Staging URL for shared load balancing | Required if shared load balancer enabled"
  type        = string
  default     = ""
  sensitive   = false
}



# SSM
variable "Staging_PARAMETERS_PATH" {
  description = ""
  type        = string
  default     = ""
  sensitive   = false
}
variable "Main_PARAMETERS_PATH" {
  description = ""
  type        = string
  default     = ""
  sensitive   = false
}
variable "parameters_region" {
  description = ""
  type        = string
  default     = ""
  sensitive   = false
}

###############################################################################################
#DO_NOT_MESS_WITH_BELOW_VALUES
###############################################################################################
# environment counts:
# count = length(var.my_variable) == length("true") ? 1 : 0
# count = length(var.my_variable_a) == length("true") || length(var.my_variable_b) == length("true") ? 1 : 0
#count = length(var.main_resource_count) == length("true") || length(var.staging_resource_count) == length("true") ? 1 : 0
variable "main_resource_count" {
  description = "Determine wether to create production related resources or not"
  type        = bool
  default     = true # Changing this value from true will cause removal of main environment resources
}
variable "staging_resource_count" {
  description = "Determine wether to create staging related resources or not"
  type        = bool
  default     = true # Changing this value from true will cause removal of staging environment resources
}
variable "shared_loadbalancer" {
  description = "Allowing shared load balancer will allow creating laod balancer listener rules with host header and assign Alias records to route53 domain, and discard cloudfront. Determine wether to create relative resources or not"
  type        = bool
  default     = true # Changing this value from true will cause removal of staging environment resources
}
