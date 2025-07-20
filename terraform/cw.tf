resource "aws_cloudwatch_log_group" "ecs_api_service" {
  name              = "/ecs/api-service"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "ecs_cluster" {
  name              = "/aws/ecs/cluster/jawsug-bgnr-66"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "kinesis_api_service" {
  name              = "/aws/kinesisfirehose/api-logs"
  retention_in_days = 30
}


