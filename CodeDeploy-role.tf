
######################################################
# CodeDeploy-Role
######################################################
resource "aws_iam_role" "codeDeploy_role" {
  name               = "codeDeploy_ec2_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.codeDeploy_role.json
}

# Assumed role (resource) used for the role
data "aws_iam_policy_document" "codeDeploy_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
#Policy Attachment
resource "aws_iam_role_policy_attachment" "codeDeploy_role" {
  role       = aws_iam_role.codeDeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}
resource "aws_iam_role_policy_attachment" "codeDeploy_role6" {
  role       = aws_iam_role.codeDeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_role_policy_attachment" "codeDeploy_role_4" {
  role       = aws_iam_role.codeDeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "codeDeploy_role_5" {
  role       = aws_iam_role.codeDeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
}

resource "aws_iam_role_policy_attachment" "codeDeploy_role_2" {
  role       = aws_iam_role.codeDeploy_role.name
  policy_arn = aws_iam_policy.codedeploy-custom-policy.arn
}


#####################################################
# End of Role
#####################################################

# Custome Policy:
resource "aws_iam_policy" "codedeploy-custom-policy" {
  name        = "codedeploy-custom-policy"
  path        = "/"
  description = "Custom Policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Additionals"
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "ec2:CreateTags",
          "ec2:RunInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3"
        Effect = "Allow"
        Action = [

          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.bucket.arn}/*",
          "${aws_s3_bucket.bucket.arn}"
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
          "ecr:UploadLayerPart",
          "ecr:BatchDeleteImage",
          "ecr:BatchGetRepositoryScanningConfiguration",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:StartLifecyclePolicyPreview",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:ReplicateImage",
          "ecr:GetRepositoryPolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DescribeRepositoryCreationTemplate",
          "ecr:GetRegistryPolicy",
          "ecr:DescribeRegistry",
          "ecr:GetAuthorizationToken",
          "ecr:CreatePullThroughCacheRule",
          "ecr:GetRegistryScanningConfiguration",
          "ecr:ValidatePullThroughCacheRule",
          "ecr:CreateRepositoryCreationTemplate",
          "ecr:BatchImportUpstreamImage",
          "ecr:UpdatePullThroughCacheRule"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowGetS3Builds",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetBucketPolicy",
          "s3:PutObjectAcl",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ],
        Resource = [
          "${aws_s3_bucket.bucket.arn}",
          "${aws_s3_bucket.bucket.arn}/*",
        ]
      },
      {
        "Sid" : "AllowSSMParameterAccess",
        "Effect" : "Allow",
        "Action" : ["ssm:GetParametersByPath"]
        "Resource" : "arn:aws:ssm:${var.region}:${var.account_id}:parameter/*"
      }
    ]
  })

}
