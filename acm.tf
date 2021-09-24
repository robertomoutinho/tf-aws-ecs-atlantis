###########################
## ACM (SSL certificate) ##
###########################

module "acm" {

  source  = "terraform-aws-modules/acm/aws"
  version = "v2.5.0"

  create_certificate = var.certificate_arn == ""
  domain_name        = var.acm_certificate_domain_name == "" ? join(".", [var.name, var.route53_zone_name]) : var.acm_certificate_domain_name
  zone_id            = var.certificate_arn == "" ? element(concat(data.aws_route53_zone.this.*.id, [""]), 0) : ""
  tags               = local.local_tags

}