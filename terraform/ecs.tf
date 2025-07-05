resource "aws_ecr_repository" "api_service" {
  name                 = "api-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "api-service"
    Project = var.project_name
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name    = "${var.project_name}-cluster"
    Project = var.project_name
  }
}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

resource "aws_ecs_task_definition" "api_service" {
  family                   = "api-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "api-service"
      image     = "${aws_ecr_repository.api_service.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ECS_CLUSTER_NAME"
          value = aws_ecs_cluster.main.name
        },
        {
          name  = "ECS_SERVICE_NAME"
          value = "api-service"
        },
        {
          name  = "CLOUDWATCH_LOG_GROUP"
          value = aws_cloudwatch_log_group.ecs_api_service.name
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "FIREHOSE_STREAM_PARQUET"
          value = aws_kinesis_firehose_delivery_stream.api_logs_parquet.name
        },
        {
          name  = "FIREHOSE_STREAM_JSON"
          value = aws_kinesis_firehose_delivery_stream.api_logs_json.name
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_api_service.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api-service"
        }
      }
    }
  ])

  tags = {
    Name    = "api-service"
    Project = var.project_name
  }
}

resource "aws_ecs_service" "api_service" {
  name            = "api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api_service.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api-service"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name    = "api-service"
    Project = var.project_name
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}
