#########################
## Secrets for webhook ##
#########################

data "aws_ssm_parameter" "github_webhook" {
  name = var.github_webhook_ssm_parameter_name
}

data "aws_ssm_parameter" "github_atlantis_user_token" {
  name = var.github_atlantis_user_token_ssm_parameter_name
}

data "aws_ssm_parameter" "github_atlantis_user_ssh_key" {
  name = var.github_atlantis_user_ssh_key_ssm_parameter_name
}