# Instance profile
resource "aws_iam_instance_profile" "Ec2ImageBuilderIAMRole" {
  name = "Ec2_Image_Builder_IAM_Role"
  role = aws_iam_role.Ec2ImageBuilderIAMRole.name
}
# Role for Ec2ImageBuilder
resource "aws_iam_role" "Ec2ImageBuilderIAMRole" {
  name               = "EC2_Image_Builder_IAM_Role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

## Policies applied

### SSMCore
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.Ec2ImageBuilderIAMRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

### EC2InstanceProfileForImageBuilder
resource "aws_iam_role_policy_attachment" "imagebuilder" {
  role       = aws_iam_role.Ec2ImageBuilderIAMRole.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

### EC2InstanceProfileForContainerBuilder
resource "aws_iam_role_policy_attachment" "containerbuilder" {
  role       = aws_iam_role.Ec2ImageBuilderIAMRole.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
}

### Custom policy
resource "aws_iam_role_policy_attachment" "custom" {
  role       = aws_iam_role.Ec2ImageBuilderIAMRole.name
  policy_arn = aws_iam_policy.S3_ECR_Auth.arn
}

resource "aws_iam_policy" "S3_ECR_Auth" {
  name        = "ec2imagebuilder_s3_ecr_auth"
  description = "access s3 and ecr policy"
  path        = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3"
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:PutObjectAcl",
          "s3:PutObject",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads",
          "s3:ListBucket",
          "s3:AbortMultipartUpload"

        ]
        Resource = [
          "*"
        ]
      },
      {
        Sid    = "ECR"
        Effect = "Allow"
        Action = [
          "ecr:DescribeImageScanFindings",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeImageReplicationStatus",
          "ecr:ListTagsForResource",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:GetRegistryPolicy",
          "ecr:DescribeRegistry",
          "ecr:GetAuthorizationToken",
          "ecr:GetRegistryScanningConfiguration",
          "ecr:ValidatePullThroughCacheRule",
          "ecr:BatchImportUpstreamImage",
          "ecr:UpdatePullThroughCacheRule",
        ]
        Resource = "*"
      },
      {
        "Sid" : "AllowSSM",
        "Effect" : "Allow",
        "Action" : ["ssm:GetParametersByPath", "ssm:UpdateInstanceInformation"]
        "Resource" : "arn:aws:ssm:${var.parameters_region}:${var.account_id}:parameter/*"
      }
    ]
  })

  lifecycle {
    prevent_destroy = false
  }
}
