# ----------------------
# Fetch Route 53 Hosted Zone
# ----------------------
data "aws_route53_zone" "main" {
  name = var.aws_route53_zone_name
}

# ----------------------
# Fetch Route 53 Hosted Zone
# ----------------------
data "aws_lb" "this" {
  arn = var.alb_arn
}
# ----------------------
# Route 53 Records
# ----------------------
resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.env == "dev" ? "${var.env}." : var.env == "staging" ? "${var.env}." : "" + "${var.project_name}.${var.aws_route53_zone_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.this.dns_name
    zone_id                = data.aws_lb.this.zone_id
    evaluate_target_health = true
  }

  set_identifier = "${var.project_name}-${var.env}-${var.region}"
  latency_routing_policy {
    region = var.region
  }
}