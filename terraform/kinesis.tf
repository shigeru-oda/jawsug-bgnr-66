resource "aws_kinesis_firehose_delivery_stream" "api_logs_json" {
  name        = "${var.project_name}-api-logs-json"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_role.arn
    bucket_arn          = aws_s3_bucket.api_logs_json.arn
    prefix              = "api-logs-json/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "api-logs-json-errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"
    custom_time_zone    = "Asia/Tokyo"

    buffering_size     = 128
    buffering_interval = 60
    compression_format = "UNCOMPRESSED"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis_api_service.name
      log_stream_name = "json-errors"
    }
  }

  tags = {
    Name    = "${var.project_name}-api-logs-json"
    Project = var.project_name
  }
}

resource "aws_kinesis_firehose_delivery_stream" "api_logs_parquet" {
  name        = "builders-flash-api-logs-parquet"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_role.arn
    bucket_arn          = aws_s3_bucket.api_logs_parquet.arn
    prefix              = "api-logs-parquet/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "api-logs-errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"
    custom_time_zone    = "Asia/Tokyo"

    buffering_size     = 128
    buffering_interval = 60
    compression_format = "UNCOMPRESSED"

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {
            compression = "SNAPPY"
          }
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_database.api_logs_database.name
        table_name    = aws_glue_catalog_table.api_logs_parquet_table.name
        role_arn      = aws_iam_role.firehose_role.arn
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis_api_service.name
      log_stream_name = "standard-errors"
    }
  }

  tags = {
    Name    = "builders-flash-api-logs-parquet"
    Project = var.project_name
  }
}
