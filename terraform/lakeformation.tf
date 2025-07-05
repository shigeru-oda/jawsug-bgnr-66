resource "aws_lakeformation_permissions" "firehose_role" {
  principal = aws_iam_role.firehose_role.arn
  permissions = ["SELECT", "DESCRIBE"]

  table {
    database_name = "builders_flash_logs"
    name          = "api_logs_parquet"
  }
}
