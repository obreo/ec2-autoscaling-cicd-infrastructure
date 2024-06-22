# Reference doc: https://registry.terraform.io/providers/hashicorpcodebuild_name/aws/latest/docs/resources/codebuild_project
# Reference doc: https://docs.aws.amazon.com/codebuild/latest/APIReference/API_Types.html
# Reference doc: https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html
resource "aws_codebuild_project" "codebuild" {
  count         = var.Docker_Application == false ? 1 : 0
  name          = "${var.name}-main"
  description   = "This is a codebuild appliaction that is used for ${var.name}"
  build_timeout = 10 #min
  service_role  = aws_iam_role.codebuild-role.arn

  # Doc: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-codebuild-project-artifacts.html
  artifacts {
    type                = "S3"
    packaging           = "ZIP"
    location            = aws_s3_bucket.bucket.id
    path                = "artifacts/main"
    namespace_type      = "NONE"
    name                = "${var.name}.zip"
    encryption_disabled = true
  }

  # You can save time when your project builds by using a cache. A cache can store reusable pieces of your build environment and use them across multiple builds. 
  # Your build project can use one of two types of caching: Amazon S3 or local. 

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_CUSTOM_CACHE"]
  }

  environment {
    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html
    compute_type = "BUILD_GENERAL1_SMALL"
    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
    image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html#environment.types
    # For Lmbda computes: Only available for environment type LINUX_LAMBDA_CONTAINER and ARM_LAMBDA_CONTAINER
    type = "LINUX_CONTAINER"
    # When you use a cross-account or private registry image, you must use SERVICE_ROLE credentials. When you use an AWS CodeBuild curated image, you must use CODEBUILD credentials.
    image_pull_credentials_type = "CODEBUILD"
  }


  logs_config {
    cloudwatch_logs {
      group_name  = "${var.name}-codebuild-log-group"
      stream_name = "${var.name}-codebuild-log-stream"
    }
  }
  # Doc: https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html
  source {
    #location                      = ""
    type = "NO_SOURCE"
    # The sed command below should use double quotes to recognise the CodeBuild ENV as it is and not as a literal string.
    # The artifacts '**/*' means match all directories & subdirectories '**' and match all files in each directory '/*'.
    buildspec = <<EOF
    version: 0.2
    env:
      variables:
        SSM_PATH: "${var.Main_PARAMETERS_PATH}"
    phases:
      install:
        runtime-versions:
          nodejs: 20
      pre_build:
        commands:
          - echo Calling Parameters
          - while read -r name value; do export_string="$${name##*/}=$value"; export "$export_string"; done < <(aws ssm get-parameters-by-path --path "$${SSM_PATH}" --with-decryption --query "Parameters[*].[Name,Value]" --output text)
          - echo installing dependencies
          - npm install -f
      build:
        commands:
          - echo Building application
          - npm run build

    artifacts:
      files:
        - '**/*'
        - scripts/*
        - appspec.yml
      base-directory: "."

    #cache:
    #  paths:
    #    - /root/.npm/**/*
    #    - node_modules/**/*
    EOF 
  }

  lifecycle {
    ignore_changes = [
      environment,
      source # Ignore changes
    ]
  }
}
#############################################################################################################################
#DOCKER APPLICATION RESOURCE
#############################################################################################################################
resource "aws_codebuild_project" "codebuild_docker" {
  count         = var.Docker_Application == true ? 1 : 0
  name          = "${var.name}-main"
  description   = "This is a codebuild appliaction that is used for ${var.name}"
  build_timeout = 10 #min
  service_role  = aws_iam_role.codebuild-role.arn

  artifacts {
    type                = "S3"
    packaging           = "ZIP"
    location            = aws_s3_bucket.bucket.id
    path                = "artifacts/main"
    namespace_type      = "NONE"
    name                = "${var.name}.zip"
    encryption_disabled = true
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_CUSTOM_CACHE"]
  }

  environment {
    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html
    compute_type = "BUILD_GENERAL1_SMALL"
    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
    image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    # https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-compute-types.html#environment.types
    # For Lmbda computes: Only available for environment type LINUX_LAMBDA_CONTAINER and ARM_LAMBDA_CONTAINER
    type = "LINUX_CONTAINER"
    # When you use a cross-account or private registry image, you must use SERVICE_ROLE credentials. When you use an AWS CodeBuild curated image, you must use CODEBUILD credentials.
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.name}-codebuild-log-group"
      stream_name = "${var.name}-codebuild-log-stream"
    }
  }
  # Doc: https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html
  source {
    type      = "NO_SOURCE"
    buildspec = <<EOF
 # This buildspec.yml script will build dockerfile of apache and update it with the static files, then push it to the ECR registry, it will then update the appspec.yml file with the new image version, and export it to s3 as an artifact.
      # Make sure that CodeBuild has role to access all the resources mentioned in this script so it can use aws api with authentication.
      
      version: 0.2
      phases:
        pre_build:
          commands:
            # Log in ECR
            - aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com
        build:
          commands:
            # Building Dockerfile
            - echo  'Building Image'
            - docker build -t ${var.name} .
            - echo 'Tagging image'
            - docker tag ${var.name}:latest ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_name}:$${CODEBUILD_BUILD_NUMBER}
        post_build:
          commands:
            # Pushing image to repository
            - echo 'Pushing Image to ECR registry'
            - docker push ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_name}:$${CODEBUILD_BUILD_NUMBER}
            # Updating before_install.sh file with the new build number tag
            - echo 'Updating before_install.sh file with the new build number tag'
            - |
                sed -i "s|<IMAGE>|${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.ecr_name}:$${CODEBUILD_BUILD_NUMBER}|g" scripts/before_install.sh
      artifacts:
        files:
          - '**/*'
    EOF 
  }

  lifecycle {
    ignore_changes = [
      environment,
      source # Ignore changes
    ]
  }
}
