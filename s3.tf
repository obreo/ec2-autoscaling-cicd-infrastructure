# This S3 Bucket is used to store the EC2 Image Builder logs and codebuild artifacts for both starging and main
# S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket        = "${var.name}-artifacts"
  force_destroy = true
}

# Versioning
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.bucket.id



  rule {
    id = "prod"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      newer_noncurrent_versions = 4
      noncurrent_days           = 7
    }

    filter {
      prefix = "artifacts/main/"
    }

    status = "Enabled"
  }

  rule {
    id = "staging"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      newer_noncurrent_versions = 4
      noncurrent_days           = 7
    }

    filter {
      prefix = "artifacts/staging/"
    }

    status = "Enabled"
  }
}

# Disable bucket ACLs to allow bucket policy
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

## Bucket policy
resource "aws_s3_bucket_policy" "allow_access_static" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.allow_access.json
}


data "aws_iam_policy_document" "allow_access" {
  statement {
    principals {
      type = "Service"
      identifiers = [
        "imagebuilder.amazonaws.com",
        "ssm.amazonaws.com",
        "codebuild.amazonaws.com",
        "codedeploy.amazonaws.com",
        "ec2.amazonaws.com",
        "codepipeline.amazonaws.com",
        "cloudformation.amazonaws.com"
      ]
    }

    actions = [
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:ListMultipartUploadParts",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucket",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:AbortMultipartUpload"
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}",
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
}