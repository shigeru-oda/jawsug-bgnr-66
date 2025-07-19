resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "athena_query_results" {
  bucket = "${var.project_name}-athena-query-results-${random_string.suffix.result}"
}
resource "aws_s3_bucket" "glue_scripts" {
  bucket = "${var.project_name}-glue-scripts-${random_string.suffix.result}"
}

resource "aws_s3_bucket" "api_logs_parquet" {
  bucket = "${var.project_name}-api-logs-parquet-${random_string.suffix.result}"
}

resource "aws_s3_bucket" "api_logs_json" {
  bucket = "${var.project_name}-api-logs-json-${random_string.suffix.result}"
}

resource "aws_s3_bucket" "api_logs_iceberg" {
  bucket = "${var.project_name}-api-logs-iceberg-${random_string.suffix.result}"
}

resource "aws_s3_directory_bucket" "api_logs_parquet_express" {
  bucket = "${var.project_name}-api-logs-parquet-${random_string.suffix.result}--apne1-az1--x-s3"

  location {
    name = "apne1-az1"
  }
}

resource "aws_s3_directory_bucket" "api_logs_json_express" {
  bucket = "${var.project_name}-api-logs-json-${random_string.suffix.result}--apne1-az1--x-s3"

  location {
    name = "apne1-az1"
  }
}
