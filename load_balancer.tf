#########
## ALB ##
#########

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "v5.13.0"

  name     = var.name
  internal = var.internal

  vpc_id          = var.vpc_id
  subnets         = var.public_subnet_ids
  security_groups = flatten([module.alb_https_sg.this_security_group_id, module.alb_http_sg.this_security_group_id, var.lb_extra_security_group_ids])

  access_logs = {
    enabled = var.alb_logging_enabled
    bucket  = var.alb_log_bucket_name
    prefix  = var.alb_log_location_prefix
  }

  https_listeners = [
    {
      target_group_index   = 0
      port                 = 443
      protocol             = "HTTPS"
      certificate_arn      = var.certificate_arn == "" ? module.acm.this_acm_certificate_arn : var.certificate_arn
      action_type          = "forward"
      authenticate_oidc    = var.alb_authenticate_oidc
      authenticate_cognito = var.alb_authenticate_cognito
    },
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = 443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
  ]

  target_groups = [
    {
      name                 = var.name
      backend_protocol     = "HTTP"
      backend_port         = var.atlantis_port
      target_type          = "ip"
      deregistration_delay = 10
    },
  ]

  tags = local.local_tags

}


resource "aws_lb_listener_rule" "unauthenticated_access_for_cidr_blocks" {

  count = var.allow_unauthenticated_access ? 1 : 0

  listener_arn = module.alb.https_listener_arns[0]
  priority     = var.allow_unauthenticated_access_priority

  action {
    type             = "forward"
    target_group_arn = module.alb.target_group_arns[0]
  }

  condition {
    source_ip {
      values = sort(compact(concat(var.allow_github_webhooks ? var.github_webhooks_cidr_blocks : [], var.whitelist_unauthenticated_cidr_blocks)))
    }
  }

}