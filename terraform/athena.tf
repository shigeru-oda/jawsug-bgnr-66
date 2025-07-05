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

  tags = {
    Name    = "${var.project_name}-api-logs-workgroup"
    Project = var.project_name
  }
}
