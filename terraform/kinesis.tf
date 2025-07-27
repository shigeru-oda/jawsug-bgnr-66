resource "aws_kinesis_firehose_delivery_stream" "api_service_json" {
  name        = "${var.project_name}-api-service-json"
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
}

resource "aws_kinesis_firehose_delivery_stream" "api_service_json_gz" {
  name        = "${var.project_name}-api-service-json-gz"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_role.arn
    bucket_arn          = aws_s3_bucket.api_logs_json_gz.arn
    prefix              = "api-logs-json-gz/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "api-logs-json-gz-errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"
    custom_time_zone    = "Asia/Tokyo"

    buffering_size     = 128
    buffering_interval = 60
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis_api_service.name
      log_stream_name = "json-gz-errors"
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "api_service_iceberg" {
  name        = "${var.project_name}-api-service-iceberg"
  destination = "iceberg"

  iceberg_configuration {
    buffering_size     = 128
    buffering_interval = 60
    role_arn           = aws_iam_role.firehose_role.arn
    catalog_arn        = "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:catalog"

    s3_configuration {
      role_arn   = aws_iam_role.firehose_role.arn
      bucket_arn = aws_s3_bucket.api_logs_iceberg.arn
      prefix     = "api-logs-iceberg/data/"
      error_output_prefix = "api-logs-iceberg/error/"
    }
    
    destination_table_configuration {
      database_name = aws_glue_catalog_database.builders_flash_logs.name
      table_name    = "buildersflash_api_logs_iceberg"
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis_api_service.name
      log_stream_name = "iceberg-errors"
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "api_service_parquet" {
  name        = "${var.project_name}-api-service-parquet"
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

    # Parquet形式への変換設定
    data_format_conversion_configuration {
      enabled = true

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
        database_name = aws_glue_catalog_database.builders_flash_logs.name
        table_name    = aws_glue_catalog_table.api_logs_parquet.name
        role_arn      = aws_iam_role.firehose_role.arn
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis_api_service.name
      log_stream_name = "parquet-errors"
    }
  }
}
