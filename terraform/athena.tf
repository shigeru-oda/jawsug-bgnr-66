resource "aws_athena_workgroup" "api_logs" {
  name        = "${var.project_name}-api-logs"
  description = "Workgroup for querying API logs"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    engine_version {
      selected_engine_version = "Athena engine version 3"
    }

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_query_results.bucket}/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

resource "aws_athena_named_query" "create_iceberg_table" {
  name        = "${var.project_name}_create_iceberg_table"
  database    = aws_glue_catalog_database.builders_flash_logs.name
  query       = <<EOT
CREATE TABLE ${var.project_name}_buildersflash_logs.buildersflash_api_logs_iceberg (
  timestamp string,
  level string,
  request_id string,
  client_ip string,
  http_method string,
  api_path string,
  status_code int,
  response_time_ms int,
  request_body struct<order_id:string,instrument:string,order_type:string,quantity:int,price:double,side:string>,
  auth_method string,
  user_agent string,
  note string,
  environment string,
  region string,
  ecs_cluster string,
  ecs_service string,
  ecs_task_id string,
  year string,
  month string,
  day string
)
PARTITIONED BY (year, month, day)
LOCATION 's3://${aws_s3_bucket.api_logs_iceberg.id}/api-logs-iceberg/'
TBLPROPERTIES (
  'table_type'='ICEBERG',
  'format'='parquet',
  'write_compression'='snappy'
)
EOT
  description = "create iceberg table"
  workgroup   = aws_athena_workgroup.api_logs.name
}

resource "aws_athena_named_query" "create_iceberg_table_query" {
  name        = "${var.project_name}_create_iceberg_table_query"
  database    = aws_glue_catalog_database.builders_flash_logs.name
  query       = <<EOT
CREATE TABLE ${var.project_name}_buildersflash_logs.buildersflash_api_logs_iceberg_query (
  timestamp string,
  level string,
  request_id string,
  client_ip string,
  http_method string,
  api_path string,
  status_code int,
  response_time_ms int,
  request_body struct<order_id:string,instrument:string,order_type:string,quantity:int,price:double,side:string>,
  auth_method string,
  user_agent string,
  note string,
  environment string,
  region string,
  ecs_cluster string,
  ecs_service string,
  ecs_task_id string,
  year string,
  month string,
  day string
)
PARTITIONED BY (year, month, day)
LOCATION 's3://${aws_s3_bucket.api_logs_iceberg.id}/query/builders_flash_logs.db/api_logs_iceberg/'
TBLPROPERTIES (
  'table_type'='ICEBERG',
  'format'='parquet',
  'write_compression'='snappy'
)
EOT
  description = "create iceberg table"
  workgroup   = aws_athena_workgroup.api_logs.name
}

# 実際にSQLを実行するリソース
resource "null_resource" "execute_iceberg_table_creation" {
  triggers = {
    # 依存関係が変更されたときに再実行
    database_id = aws_glue_catalog_database.builders_flash_logs.id
    workgroup_id = aws_athena_workgroup.api_logs.id
    bucket_id = aws_s3_bucket.api_logs_iceberg.id
  }

  provisioner "local-exec" {
    command = <<EOT
aws athena start-query-execution \
  --query-string "${aws_athena_named_query.create_iceberg_table.query}" \
  --query-execution-context Database="${aws_glue_catalog_database.builders_flash_logs.name}" \
  --work-group "${aws_athena_workgroup.api_logs.name}" \
  --region "${var.aws_region}" \
  --output text
EOT
  }

  depends_on = [
    aws_glue_catalog_database.builders_flash_logs,
    aws_athena_workgroup.api_logs,
    aws_s3_bucket.api_logs_iceberg
  ]
}

resource "aws_athena_named_query" "insert_iceberg_table_query" {
  name        = "${var.project_name}_insert_iceberg_table_query"
  database    = aws_glue_catalog_database.builders_flash_logs.name
  query       = <<EOT
INSERT INTO ${var.project_name}_buildersflash_logs.buildersflash_api_logs_iceberg_query
SELECT * 
FROM ${var.project_name}_buildersflash_logs.buildersflash_api_logs_parquet
EOT
  description = "insert data to iceberg table"
  workgroup   = aws_athena_workgroup.api_logs.name
}
