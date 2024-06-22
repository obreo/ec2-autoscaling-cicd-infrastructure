# Autoscalable EC2 Infrastructure with CI/CD Integration and Blue/Green Deployment Strategy using custom AMI, Written in IaC - Terraform

## This is an EC2 Autoscaling group infrastructure, integrated with CI(CodeBuild or BitBucket) / CD(CodeDeploy) and Blue/Green deployment strategy using custom AMI image, allows Shared or dedicated load balancer for both Containerized and un-Containerized appications.

## Architecture

![Architecture](/architecture.png)

## Overview

This tutorial explains how to deploy a scalable, highly available EC2 infrastrucutre, based on a custom AMI image, and supports continues integration/continues delivery (CI/CD) deployment with blue / green strategy, integrated with multi environments using a shared application load balancer, or dedicated backed by CloudFront distribution.

This infrastructure depends on a VPC of two subnets to run application instances, attached to a route table that uses Internet gateway, having EC2 instances deployed by an autoscaling group, that uses an application load balancer and a launch template, which uses a custome EC2 image based on Amazon Linux 2023 - built by EC2 Image Builder - which supports AWS CodeDeploy-Agent, AWS CloudWatch-Agent, NodeJS runtime and Docker engine.

It supports metrics and log monitoring using cloudwatch agent. 

This Insfrastructure runs a CICD deployment using codepipeline that triggers a Code Build application to build a dockerfile / application (if requried) and push it as artifact or ECR registry, that is used by codedeploy to deliver the code and run the command set it in the EC2 instances under blue/green deployment type.

## Brief Intro - Why and How?

Deploying Autoscalable EC2 infrastructure integrated with CI/CD pipelines from the scratch is not the best idea considering its complexity and the amount of resources required to manage such infrastructure. But it is useful when it is desired to have a complete control over the infrastructure. 

While implementing this setup, I realised I was implementing that Elastic Beanstalk is already delivering. In fact, Elastic Beanstalk is typically based on such backend infrastructure from a base image which includes codedeploy-agent to deliver and run the application, CloudWatch agent to deliver metrics and logs, Nginx to deliver proxy server, and the software runtime that will run the application's code.

It uses application load balancer that is either dedicated, or shared using hostname rules baed on Alias records that route the custom domain name to the application load balancer's endpoint. It also uses S3 Bucket which stores the application's code for deployment.

One of the main issues of elastic beanstalk is the slow deployment process, and this process of building the application, pushing it as an artifact to s3 bucket, then retrieving it for deployment to the ec2 instances and waitng for health checks explains the slow deployment process.

But another reason to build an Autoscalable EC2 infrastructure instead of Elastic Beanstalk is the later has 500mb application size limit, which is enough especially if the application uses isolated infrastructure for each of Frontend and Backend.

## Setup

### How To

Running this infrastructure depends on the values set in thr `variables.tf` file. It detects whether to deploy shared or dedicated load balancer, Staging or Production envionments or both.

### Pre Install

For shared load balancer, it is required to create a Route53 hostzone that will have the host domain name. After that use the host zone ID and add the production domain and staging domain names in the `variables.tf` values.

For dedicated load balancer, cloudfront will be created, and the load balancer will be connected to the production envrionment only. There is no need to add Alias records neither create hostzone during the infrastructure's perperation.

For SSL setup for Application load balancer, create an SSL certificate from ACM and verify it by setting its record in Route53. Then use the SSL certificate's ARN in the `variables.tf`

Set all the values as directed in the `variables.tf` file.

### Post Install

After running the Terraform script, it will release the following files, include them in the source code repository:
1. appspec.yml
2. ./scripts/scripts folder; includes the bash scripts that will run by appspec.yml
3. Dockerfile - in case running containerized applciation

Create a CodePipeline pipeline for each envrionment, link it to the git repository, its related codebuild and codedeploy applications.

Let the pipeline run and test the application.

## Infrastructure

1. VPC
   1. The VPC uses two subnets and two optional subnets for RDS in case deployed. It uses an internet gateway and three secutiry groups; one for the autoscaling group, one for the load balancer, and a third - optional - for the RDS.
   2. The autoscaling group subnets are connected to a route table that routes to the internet gateway.
   3. The autoscaling group's security groups allow inbound access to HTTP, SSH, and HTTPS, while the Application Load balancer's security group allows inbound to HTTP and HTTPS.
   4. To allow creating RDS subnets with a security group, then modify the default value of `rds_port` to a value other than 0
   5. There's a shaded ACL resource in VPC.tf that is used to allow access only to a certain port and IP for the RDS subnets. This can be used if the RDS subnets were used and attached to the route table resource used in the VPC.tf

2. EC2 Image Builder
   1. The EC2 Image Builder is used to build a custom AMI image that will have:
      1. CodeDeploy-agent; which is required to allow codedeploy access the instance and implement the commands prepared in the `appspec.yml` file - will be discussed below.
      2. CloudWatch-agent; this is used to allow cloudwatch grab metrics and logs from the EC2 instance.
      3. Docker engine; to run container images.
      4. Nginx server.
      5. NodeJS runtime.
      6. The AMI created is based on Amazon Linux 2023, it includes SSM agent installed, otherwise it must be added as well, as SSM is used to install the above components to the cutome image.
      
   2. Role; A universal role for different purposes for EC2 Image Builder:
      1. An instance profile is created with a role that has the following:
            1. AmazonSSMManagedInstanceCore; to allow EC2 connect with SSM
            2. EC2InstanceProfileForImageBuilder; this is required by EC2 Image Builder if an image is created.
            3. EC2InstanceProfileForImageBuilderECRContainerBuilds; This is required bhy EC2 Image Builder, if container is created.
            4. Cutome role; to get objects from S3 - some AWS components depend on S3 based files like codedeploy-agent - and get image from ECR registry.

   3. Components:
      1. As mentioned in 2.1, five components were created for the AMI, but the Docker & CodeDeploy-agent components were created manually due to an error prevented them being created using the AWS managed components.
      2. The custom components use `.yaml` template that can be explained in the [AWS Documentation](https://docs.aws.amazon.com/imagebuilder/latest/userguide/create-component-yaml.html)
      3. **chkconfig**; in the first component I installed two packages, one is *chkconfig*, that is a systemd managed tool by AWS for the AWS AMIs, this allows enabling the systemd services as systemctl enable is not supported on AWS AMIs.
      4. **CodeDeploy-agent**; this is the second package, that was grabbed from [AWS Documnetation](https://docs.aws.amazon.com/codedeploy/latest/userguide/codedeploy-agent-operations-install-cli.html) for CodeDeploy-Agent. Where *chkconfig* was used to enable the codedeplo-agent service once the instance starts.
      
      (Optional) A validation step was created to validate the CodeDeploy installation.
      5. **Docker**; Install docker manually as installed for any linux distribution, then let **ec2-user** be a part of the docker group to avoid root credentials when using docker commands. Once the AMI is launched the session will already be restarted so no need to restart the session to after adding the user to a new group.
      NOTE: Amazon linux linux distros use **ec2-user** as the [default](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/managing-users.html#ami-default-user-names) user.

   4. Infrastructure Configuration:
      1. This configuratuion is used for the environment that will build the AMI image.
      2. It includes the security groups, subnets, launch template and more can be assigned from the terraform arguments.
      3. In case any error popped while creating the image, make the `terminate_instance_on_failure = false` to investigate the logs inside the EC2 instance that is building the AMI.
      4. The environment logs are also exported to the S3 bucket that will be discussed below.

   5. Image Recipe
      1. This is where we define the base image that will be used to create our custom AMI, User-Data in case any bash commands are required to modify/install packages, and the components to be installed in the AMI image.
      2. The base AMI image used is Amazon Linux 2023 - the AMI ID can be found in the AMI market place in EC2 launch configuration.
      3. The components have three categories; Owned, which are custom components created by the user. AWS managed; created by AWS, third party. All the components can be found in their section in the EC2 image builder and each has its own ARN.

   6. Image Release
      1. This is where the custom AMI is created, it is either triggered instantly using the Image resource or scheduled using a pipeline resource. Using a Pipeline resource in Terraform lacks attribute for getting the custom AMI ID, which is required for the Launch Template resource, for this I used the Image resource instead of the Image_pipeline resource.

3. S3 bucket & ECR registry
   1. S3 Bucket is created to store the EC2 Image Builder logs for the Image creation, it is also used to store the CI artifact builds in case of third party CI tools was used.
   2. ECR resgistry is created to store the docker images built by CodeBuild that will be pulled by the codedeploy agent in each EC2 instance in the autoscaling group.

4. Launch Template
   1. A Template is created to be used by the Autoscaling group that willbe used by codedeploy for the blue green deployment as well as provide scalability and high availability.
   2. It uses the same instance profile used with the EC2 Image Builder.
   3. It uses the SSH-Key Created by `aws_key_pair` resource.
   4. It uses the custom AMI image created by the EC2 Image Builder.
   5. It also uses a userdata file using bash script that is written manually - to start cloudwatch agent, call SSM parameters for the environment, and set NodeJS npm start in Systemed.

5. Load Balancer
   1. An application load balancer is used that routes between the primary and secondary instance subnets used by the autoscaling group.
   2. It listens to port 80 and forwards the traffic to a target group that uses port 80. To use HTTPS, add a TLS certificate to the ALB and make it listen to HTTPS and forward the traffic to the target group that uses port 80. This works as the ALB decrypts the TLS certiicate before forwarding it to the target group as it uses layer 7 of OSI model. Unlike NLB, which runs in Layer 4, that means the transferred packates will require a TLS certificate installed in the instance to terminate the TLS encryption.

6. Autoscaling Group
   1. An Autoscaling group (AG) assigned to two subnets, with max of 2 scale out and min of 1 scale in instance under targetscaling policy.
   2. The AG uses the target group which listens to the ELB listener's traffic, this makes the AG use the ELB created earlier.
   3. The autoscaling group uses the Launch Template created earlier - based on the environment created.

7. CodeBuild
   1. This CodeBuild will run a buildspec.yml script, that will use the application source to build it and push the artifacts.
   2. There are two buildspec.yml scripts, one that builds the applciation and another uses docker build.
   3. For Uncontainerized, the compiled app will be stored as artifact to be used by codedeploy. For containerized, it will modify the  `before_install.sh` file to use the latest image tag that was pushed to ECR by codebuild.

8.  CodeDeploy
    1.  Code Deploy application is created to deploy the new image to the autoscaling group using Blue/Green deployment.
    2.  The configuration allows rolling back, and copying the autoscaling group for a new deployment, then swapping to it and terminating the old autoscaling group.
    3.  The load balancer is specified by specifying the target group used as mentioned in the `codedeploy.tf`.
    4.  A role is used that includes: `AWSCodeDeployRole`, `AmazonEC2RoleforAWSCodeDeploy`, `AmazonEC2ContainerRegistryFullAccess`, `AmazonEC2FullAccess`, `AutoScalingFullAccess`, and a `custom policy`.
    5.  CodeDeploy uses appspec.yml file that will run `before_install.sh` and `after_install.sh` file as the root user.
    6.  For docker applications, the `before_install.sh` file will run scripts that will stop all the default running containers, clean the containers and images, then run login the ECR registry, run the image pushed by codebuild.

9.  CodePipeline
    1.  A pipeline is created to run the codecommit, codebuild, and codedeploy workflow whenever a GIT event trigger is created.

# Autoscalability Behavior
Whenever a new instance is started by the autoscaling group after the first successful codedeploy deployment, codedeploy will run a hook event that will deploy the latest build push to the new instance. This hook event is set automatically to the autoscaling group hook events.

# Monitoring:
To allow monitoring work, we need to generate a configuration file using the cloudwatch wizard inside the instance. To generate a new log file:
```
./opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```

The default cloudwatch configuration file is stored in the following directory in EC2:
```
/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

After file generation, start the cloudwatch agent:
```
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

Make sure the instance-profile has the required policies to create and put logs and metrics for cloudwatch. The Metrics can be browsed in the metrics section of Cloudwathc under the `CWAgent`, while the logs can be viewed inside the logs section.

# Troubleshooting
1. Make sure that the codedeploy-agent is running in the instance using `systemctl status codedeploy-agent`
2. Check the codedeploy logs from
   1.  `/opt/codedeploy-agent/deployment-root/deployment-group-ID/deployment-ID/logs/scripts.log`
   2.  `less /var/log/aws/codedeploy-agent/codedeploy-agent.log`
   3.  If no logs available, you can go to `CodeDeploy > Deployments > Deployment ID > Deployment lifecycle events > event` in the AWS dashboard.
3.  If codedeploy error is giving **Unknown**, check the appspec.yml template and validate it.
4.  Make sure the instance profile used by the launch template has a role attached to access the ECR registry.
5.  CodeDeploy agent starts deployment once the instance is launched, it does not consider the **userdata** proccessing steps which may create a conflict. If the .env file have been created by the SSM parameter store after codedeploy agent executes the application start up, then a workaround is to remove the step of the .env creation in the userdata and add it in the **before_install** step that will run by codedeploy by edting the `before_install.sh` script from the `appspec scripts.tf` file. However, this may create a conflict if multi envrionment is created and maintained in a version control repository.