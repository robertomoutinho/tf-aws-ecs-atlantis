#########
## ECS ##
#########

resource "aws_ecs_service" "atlantis" {
  name    = var.name
  cluster = var.ecs_cluster_id
  task_definition = "${data.aws_ecs_task_definition.atlantis.family}:${max(
    aws_ecs_task_definition.atlantis.revision,
    data.aws_ecs_task_definition.atlantis.revision,
  )}"
  desired_count                      = var.ecs_service_desired_count
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = var.ecs_service_deployment_maximum_percent
  deployment_minimum_healthy_percent = var.ecs_service_deployment_minimum_healthy_percent

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [module.atlantis_sg.this_security_group_id]
    assign_public_ip = var.ecs_service_assign_public_ip
  }

  load_balancer {
    container_name   = var.name
    container_port   = var.atlantis_port
    target_group_arn = element(module.alb.target_group_arns, 0)
  }

  tags = local.local_tags
}

module "container_definition_github" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "v0.58.1"

  container_name  = var.name
  container_image = local.atlantis_image

  container_cpu                = var.ecs_task_cpu
  container_memory             = var.ecs_task_memory
  container_memory_reservation = var.container_memory_reservation

  port_mappings = [
    {
      containerPort = var.atlantis_port
      hostPort      = var.atlantis_port
      protocol      = "tcp"
    },
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.atlantis.name
      awslogs-stream-prefix = "ecs"
    }
    secretOptions = []
  }

  environment = local.container_definition_environment

  secrets = concat(
    local.container_definition_secrets_1,
    local.container_definition_secrets_2,
    local.container_definition_secrets_3,
    var.custom_environment_secrets,
  )

}

resource "aws_ecs_task_definition" "atlantis" {

  family                   = var.name
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  container_definitions    = module.container_definition_github.json_map_encoded_list

  tags = local.local_tags
}

data "aws_ecs_task_definition" "atlantis" {
  task_definition = var.name

  depends_on = [aws_ecs_task_definition.atlantis]
}