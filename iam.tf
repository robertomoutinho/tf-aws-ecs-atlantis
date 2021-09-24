#########
## IAM ##
#########

data "aws_iam_policy_document" "ecs_tasks" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.name}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks.json
  tags               = local.local_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  count      = length(var.policies_arn)
  role       = aws_iam_role.ecs_task_execution.id
  policy_arn = element(var.policies_arn, count.index)
}

###############
## PowerUser ##
###############

// data "aws_iam_policy" "PowerUser" {
//   arn = "arn:aws:iam::aws:policy/PowerUserAccess"
// }

// resource "aws_iam_role_policy_attachment" "sto-readonly-role-policy-attach" {
//   role       = aws_iam_role.ecs_task_execution.name
//   policy_arn = data.aws_iam_policy.PowerUser.arn
// }

#################
## Assume role ##
#################

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Terraform"
    ]

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_task_assume_role" {

  name = "AtlantisGrantAssumeRole"
  role = aws_iam_role.ecs_task_execution.id
  policy = element(
    compact(
      concat(
        data.aws_iam_policy_document.ecs_task_assume_role.*.json,
      ),
    ),
    0,
  )

}

###################
## Secrets Acess ##
###################

data "aws_iam_policy_document" "ecs_task_access_secrets" {
  statement {
    effect = "Allow"

    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/atlantis/*",
    ]

    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
    ]
  }
}

resource "aws_iam_role_policy" "ecs_task_access_secrets" {

  name = "ECSTaskAccessSecretsPolicy"
  role = aws_iam_role.ecs_task_execution.id
  policy = element(
    compact(
      concat(
        data.aws_iam_policy_document.ecs_task_access_secrets.*.json,
      ),
    ),
    0,
  )

}

####################
## Backend Access ##
####################

data "aws_iam_policy_document" "ecs_task_access_backend" {
  statement {
    effect = "Allow"

    resources = [
      "arn:aws:s3:::*",
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*"
    ]

    actions = [
      "s3:*",
      "dynamodb:*"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_task_access_backend" {

  name = "ECSTaskAccessBackendPolicy"
  role = aws_iam_role.ecs_task_execution.id
  policy = element(
    compact(
      concat(
        data.aws_iam_policy_document.ecs_task_access_backend.*.json,
      ),
    ),
    0,
  )

}
