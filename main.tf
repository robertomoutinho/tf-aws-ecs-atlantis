data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {

  # Atlantis
  atlantis_image = var.atlantis_image == "" ? "runatlantis/atlantis:${var.atlantis_version}" : var.atlantis_image

  atlantis_url = "https://${coalesce(
    var.atlantis_fqdn,
    element(concat(aws_route53_record.atlantis.*.fqdn, [""]), 0),
    module.alb.this_lb_dns_name,
    "_"
  )}"

  atlantis_url_events = "${local.atlantis_url}/events"

  container_definition_environment = [
    {
      name  = "ATLANTIS_LOG_LEVEL"
      value = var.atlantis_log_level
    },
    {
      name  = "ATLANTIS_PORT"
      value = var.atlantis_port
    },
    {
      name  = "ATLANTIS_ATLANTIS_URL"
      value = local.atlantis_url
    },
    {
      name  = "ATLANTIS_GH_USER"
      value = var.github_atlantis_user
    },
    {
      name  = "ATLANTIS_REPO_WHITELIST"
      value = join(",", var.github_repo_whitelist)
    },
    {
      name  = "ATLANTIS_HIDE_PREV_PLAN_COMMENTS"
      value = var.atlantis_hide_prev_plan_comments
    },
    {
      name  = "ATLANTIS_AUTOMERGE"
      value = true
    },
    {
      name  = "ATLANTIS_REPO_CONFIG"
      value = "/atlantis/repos.yaml"
    }
  ]

  # Secret access tokens
  container_definition_secrets_1 = [
    {
      name      = "ATLANTIS_GH_TOKEN"
      valueFrom = var.github_atlantis_user_token_ssm_parameter_name
    },
  ]

  # Webhook secrets are not supported by BitBucket
  container_definition_secrets_2 = [
    {
      name      = "ATLANTIS_GH_WEBHOOK_SECRET"
      valueFrom = var.github_webhook_ssm_parameter_name
    },
  ]

  container_definition_secrets_3 = [
    {
      name      = "GITHUB_USER_SSH_KEY"
      valueFrom = var.github_atlantis_user_ssh_key_ssm_parameter_name
    },
  ]

  local_tags = merge(
    {
      Name        = var.name,
      System      = "Atlantis",
      Environment = var.environment
    },
    var.tags,
  )

}