# Firehose roleの権限（既存）
resource "aws_lakeformation_permissions" "firehose_role" {
  principal = aws_iam_role.firehose_role.arn
  permissions = ["ALL"]

  table {
    database_name = "builders_flash_logs"
    name          = "api_logs_parquet"
  }
}

