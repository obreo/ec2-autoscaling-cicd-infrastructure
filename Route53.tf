# This is used to set Alias DNS records to the elastic load balancer.
# Production
resource "aws_route53_record" "prod" {
  count   = var.shared_loadbalancer == true ? 1 : 0
  zone_id = var.zone_id
  name    = var.production_url
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
    evaluate_target_health = false
  }
}

# Staging
resource "aws_route53_record" "staging" {
  count   = var.shared_loadbalancer == true ? 1 : 0
  zone_id = var.zone_id
  name    = var.staging_url
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
    evaluate_target_health = false
  }
}