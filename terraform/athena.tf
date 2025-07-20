resource "aws_athena_workgroup" "api_logs" {
  name        = "${var.project_name}-api-logs"
  description = "Workgroup for querying API logs"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_query_results.bucket}/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

resource "aws_athena_named_query" "api_logs_parquet_flat_view" {
  name        = "${var.project_name}-api_logs_parquet_flat_view"
  database    = aws_glue_catalog_database.builders_flash_logs.name
  query       = <<EOT
CREATE OR REPLACE VIEW api_logs_parquet_flat_view AS
SELECT
  timestamp,
  level,
  request_id,
  client_ip,
  http_method,
  api_path,
  status_code,
  response_time_ms,
  request_body.order_id      AS order_id,
  request_body.instrument    AS instrument,
  request_body.order_type    AS order_type,
  request_body.quantity      AS quantity,
  request_body.price         AS price,
  request_body.side          AS side,
  auth_method,
  user_agent,
  note,
  environment,
  region,
  ecs_cluster,
  ecs_service,
  ecs_task_id
FROM api_logs_parquet
EOT
  description = "View to flatten request_body struct in api_logs_parquet"
  workgroup   = aws_athena_workgroup.api_logs.name
}

resource "aws_athena_named_query" "api_logs_json_flat_view" {
  name        = "${var.project_name}-api_logs_json_flat_view"
  database    = aws_glue_catalog_database.builders_flash_logs.name
  query       = <<EOT
CREATE OR REPLACE VIEW api_logs_json_flat_view AS
SELECT
  timestamp,
  level,
  request_id,
  client_ip,
  http_method,
  api_path,
  status_code,
  response_time_ms,
  request_body.order_id      AS order_id,
  request_body.instrument    AS instrument,
  request_body.order_type    AS order_type,
  request_body.quantity      AS quantity,
  request_body.price         AS price,
  request_body.side          AS side,
  auth_method,
  user_agent,
  note,
  environment,
  region,
  ecs_cluster,
  ecs_service,
  ecs_task_id
FROM api_logs_json
EOT
  description = "View to flatten request_body struct in api_logs_json"
  workgroup   = aws_athena_workgroup.api_logs.name
}
