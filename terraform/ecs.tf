# ===================================================
# ECS Resources - Simplified Architecture
# API Service sends directly to Firehose
# ===================================================

# API Service ECR Repository
resource "aws_ecr_repository" "api_service" {
  name                 = "api-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }



  tags = {
    Name = "api-service"
  }
}



# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "jawsug-bgnr-66"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_cluster.name
      }
    }
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "jawsug-bgnr-66"
  }
}

# ECS Task Definition - Simplified
resource "aws_ecs_task_definition" "api_service" {
  family                   = "api-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "api-service"
      image = "${aws_ecr_repository.api_service.repository_url}:latest"
      
      cpu    = 1024
      memory = 2048
      
      essential = true
      
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = var.aws_region
        },
        {
          name  = "ECS_CLUSTER_NAME"
          value = aws_ecs_cluster.main.name
        },
        {
          name  = "ECS_SERVICE_NAME"
          value = "api-service"
        },
        {
          name  = "FIREHOSE_JSON_STREAM"
          value = aws_kinesis_firehose_delivery_stream.api_service_json.name
        },
        {
          name  = "FIREHOSE_PARQUET_STREAM"
          value = aws_kinesis_firehose_delivery_stream.api_service_parquet.name
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_api_service.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "api-service"
          awslogs-create-group  = "true"
        }
      }
    }
  ])

  tags = {
    Name = "api-service"
  }
}

# ECS Service
resource "aws_ecs_service" "api_service" {
  name            = "api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api_service.arn
    container_name   = "api-service"
    container_port   = 8000
  }

  depends_on = [
    aws_lb_listener.api_service,
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
    aws_iam_role_policy_attachment.ecs_task_role_firehose
  ]

  tags = {
    Name = "api-service"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "ecs_cluster" {
  name              = "/aws/ecs/cluster/jawsug-bgnr-66"
  retention_in_days = 7

  tags = {
    Name = "ECS Cluster Logs"
  }
}
