resource "aws_cloudwatch_log_group" "ecs_api_service" {
  name              = "/ecs/api-service"
  retention_in_days = 30

  tags = {
    Name    = "/ecs/api-service"
    Project = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "kinesis_api_service" {
  name              = "/aws/kinesisfirehose/api-logs"
  retention_in_days = 30

  tags = {
    Name    = "/aws/kinesisfirehose/api-logs"
    Project = var.project_name
  }
}
