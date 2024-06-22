# This resource only works if shared load balancer is disabled in the varaibles section.
resource "aws_cloudfront_distribution" "distribution" {
  count = var.shared_loadbalancer == true ? 0 : 1
  origin {
    domain_name = aws_lb.load_balancer.dns_name
    origin_id   = var.name


    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    origin_shield {
      enabled              = true
      origin_shield_region = "eu-west-1"
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${var.name}-main"
    # Doc: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    # Doc: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-origin-request-policies.html
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    # Doc: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html#managed-response-headers-policies-cors
    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c"
    viewer_protocol_policy     = "https-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "main"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  lifecycle {
    ignore_changes = [
      viewer_certificate
    ]
  }
}
