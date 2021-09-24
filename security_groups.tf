#####################
## Security groups ##
#####################

module "alb_https_sg" {

  source  = "terraform-aws-modules/security-group/aws//modules/https-443"
  version = "v3.18.0"

  name                = "${var.name}-alb-https"
  vpc_id              = var.vpc_id
  description         = "Security group with HTTPS ports open for specific IPv4 CIDR block (or everybody), egress ports are all world open"
  ingress_cidr_blocks = var.github_webhooks_cidr_blocks
  tags                = local.local_tags

}

module "alb_http_sg" {

  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "v3.18.0"

  name                = "${var.name}-alb-http"
  vpc_id              = var.vpc_id
  description         = "Security group with HTTP ports open for specific IPv4 CIDR block (or everybody), egress ports are all world open"
  ingress_cidr_blocks = var.github_webhooks_cidr_blocks
  tags                = local.local_tags

}

module "atlantis_sg" {

  source  = "terraform-aws-modules/security-group/aws"
  version = "v3.18.0"

  name        = var.name
  vpc_id      = var.vpc_id
  description = "Security group with open port for Atlantis (${var.atlantis_port}) from ALB, egress ports are all world open"

  ingress_with_source_security_group_id = [
    {
      from_port                = var.atlantis_port
      to_port                  = var.atlantis_port
      protocol                 = "tcp"
      description              = "Atlantis"
      source_security_group_id = module.alb_https_sg.this_security_group_id
    },
  ]

  egress_rules = ["all-all"]

  tags = local.local_tags

}