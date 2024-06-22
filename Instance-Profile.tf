# Instance profile
# Use an instance profile to pass an IAM role to an EC2 instance. 
resource "aws_iam_instance_profile" "instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_assume_role.name
}

# Role to be passed
resource "aws_iam_role" "ec2_assume_role" {
  name               = "ec2-instance-profile-assume-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Assumed role (resource) used for the role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


# Provides EC2 access to S3 bucket to download revision. This role is needed by the CodeDeploy agent on EC2 instances (codedeploy elastic beanstalk deployment)
resource "aws_iam_role_policy_attachment" "ec2_policy_1" {
  role       = aws_iam_role.ec2_assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# Custom policy below
resource "aws_iam_role_policy_attachment" "ec2_policy_2" {
  role       = aws_iam_role.ec2_assume_role.name
  policy_arn = aws_iam_policy.ec2_additionals.arn
}

resource "aws_iam_role_policy_attachment" "ec2_policy_3" {
  role       = aws_iam_role.ec2_assume_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

####################################
# elatic beanstalk additionals - Policy details
resource "aws_iam_policy" "ec2_additionals" {
  name        = "ec2-custome-role"
  path        = "/"
  description = "Additional policies required for ec2 with codedeploy cicd"

  # Terraform expression result to valid JSON syntax.
  # Below, ECR resources used for ECR repository - in case of using docker runner.
  # S3 resources to use the s3 bucket for retrieval of app version.
  # Elastic load balancer policies used for elastic beanstalk load balanced type, for the instance profile so ec2 instances allow routing to the load balancer.
  # EC2 policies to resolve authorization error.
  # SSM policies for elastic beanstalk patch updates and parameter store access.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "AllowingaccesstoECRrepositories",
        "Effect" : "Allow",
        "Action" : [
          "ecr:DescribeRepositoryCreationTemplate",
          "ecr:GetRegistryPolicy",
          "ecr:DescribeImageScanFindings",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRegistry",
          "ecr:DescribePullThroughCacheRules",
          "ecr:DescribeImageReplicationStatus",
          "ecr:GetAuthorizationToken",
          "ecr:ListTagsForResource",
          "ecr:BatchGetRepositoryScanningConfiguration",
          "ecr:GetRegistryScanningConfiguration",
          "ecr:ValidatePullThroughCacheRule",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowingAccessToELBResources",
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:DescribeLoadBalancerPolicyTypes",
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTrustStoreAssociations",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancerPolicies",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeInstanceHealth",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTrustStoreRevocations",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeTrustStores",
          "elasticloadbalancing:DescribeAccountLimits",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:*"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Additonals",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListAllMyBuckets",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeRouteTables",
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowaccesstocustomS3buckett",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:GetBucketPolicy",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:ListMultipartUploadParts"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.name}-artifacts",
          "arn:aws:s3:::${var.name}-artifacts/*"
        ]
      },
      {
        "Sid" : "AllowSSM",
        "Effect" : "Allow",
        "Action" : ["ssm:GetParametersByPath", "ssm:UpdateInstanceInformation", "ssm:PutParameter"]
        "Resource" : "arn:aws:ssm:${var.parameters_region}:${var.account_id}:parameter/*"
      },
      {
        "Sid" : "Logs",
        "Effect" : "Allow",
        "Action" : [
          "logs:UpdateLogDelivery",
          "logs:PutDeliverySource",
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:PutMetricFilter",
          "logs:PutRetentionPolicy",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:*:${var.account_id}:log-group:*",
          "arn:aws:logs:*:${var.account_id}:log-group:*:log-stream:*",
          "arn:aws:logs:*:${var.account_id}:delivery-source:*"
        ]
      }
    ]
  })
}
