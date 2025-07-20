resource "aws_glue_catalog_database" "builders_flash_logs" {
  name = "${var.project_name}-buildersflash-logs"
}
# S3 Standard/JSON+GZIP圧縮
resource "aws_glue_catalog_table" "api_logs_json" {
  name          = "${var.project_name}-api-logs-json"
  database_name = aws_glue_catalog_database.builders_flash_logs.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification"            = "json"
    "typeOfData"                = "file"
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2024,2026"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "projection.month.digits"   = "2"
    "projection.day.type"       = "integer"
    "projection.day.range"      = "1,31"
    "projection.day.digits"     = "2"
    "storage.location.template" = "s3://${aws_s3_bucket.api_logs_json.bucket}/api-logs-json/year=$${year}/month=$${month}/day=$${day}"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.api_logs_json.bucket}/api-logs-json/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "json-serde"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = {
        "ignore.malformed.json" = "true"
        "dots.in.keys"          = "false"
        "case.insensitive"      = "true"
        "mapping"               = "true"
      }
    }

    # JSONテーブルのcolumnsをParquetテーブルと同じ順序・カラム名・型に揃える
    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "level"
      type = "string"
    }
    columns {
      name = "request_id"
      type = "string"
    }
    columns {
      name = "client_ip"
      type = "string"
    }
    columns {
      name = "http_method"
      type = "string"
    }
    columns {
      name = "api_path"
      type = "string"
    }
    columns {
      name = "status_code"
      type = "int"
    }
    columns {
      name = "response_time_ms"
      type = "int"
    }
    columns {
      name = "request_body"
      type = "struct<order_id:string,instrument:string,order_type:string,quantity:int,price:double,side:string>"
    }
    columns {
      name = "auth_method"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "note"
      type = "string"
    }
    columns {
      name = "environment"
      type = "string"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "ecs_cluster"
      type = "string"
    }
    columns {
      name = "ecs_service"
      type = "string"
    }
    columns {
      name = "ecs_task_id"
      type = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "string"
  }

  partition_keys {
    name = "month"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }
}

# S3 Standard/Parquet
resource "aws_glue_catalog_table" "api_logs_parquet" {
  name          = "${var.project_name}-api-logs-parquet"
  database_name = aws_glue_catalog_database.builders_flash_logs.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification"            = "parquet"
    "typeOfData"                = "file"
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2024,2026"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "projection.month.digits"   = "2"
    "projection.day.type"       = "integer"
    "projection.day.range"      = "1,31"
    "projection.day.digits"     = "2"
    "storage.location.template" = "s3://${aws_s3_bucket.api_logs_parquet.bucket}/api-logs-parquet/year=$${year}/month=$${month}/day=$${day}"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.api_logs_parquet.bucket}/api-logs-parquet/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    # Parquet用テーブルのcolumnsをjsonテーブルの順序に合わせて並べ替え、http_method, client_ip, api_pathも追加
    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "level"
      type = "string"
    }
    columns {
      name = "request_id"
      type = "string"
    }
    columns {
      name = "client_ip"
      type = "string"
    }
    columns {
      name = "http_method"
      type = "string"
    }
    columns {
      name = "api_path"
      type = "string"
    }
    columns {
      name = "status_code"
      type = "int"
    }
    columns {
      name = "response_time_ms"
      type = "int"
    }
    columns {
      name = "request_body"
      type = "struct<order_id:string,instrument:string,order_type:string,quantity:int,price:double,side:string>"
    }
    columns {
      name = "auth_method"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "note"
      type = "string"
    }
    columns {
      name = "environment"
      type = "string"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "ecs_cluster"
      type = "string"
    }
    columns {
      name = "ecs_service"
      type = "string"
    }
    columns {
      name = "ecs_task_id"
      type = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "string"
  }

  partition_keys {
    name = "month"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }
}

# S3 Express One Zone/JSON+GZIP圧縮
resource "aws_glue_catalog_table" "api_logs_json_express" {
  name          = "${var.project_name}-api-logs-json-express"
  database_name = aws_glue_catalog_database.builders_flash_logs.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification"            = "json"
    "typeOfData"                = "file"
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2024,2026"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "projection.month.digits"   = "2"
    "projection.day.type"       = "integer"
    "projection.day.range"      = "1,31"
    "projection.day.digits"     = "2"
    "storage.location.template" = "s3://${aws_s3_directory_bucket.api_logs_json_express.bucket}/api-logs-json/year=$${year}/month=$${month}/day=$${day}"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_directory_bucket.api_logs_json_express.bucket}/api-logs-json/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "json-serde"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = {
        "ignore.malformed.json" = "true"
        "dots.in.keys"          = "false"
        "case.insensitive"      = "true"
        "mapping"               = "true"
      }
    }

    # JSONテーブルのcolumnsをParquetテーブルと同じ順序・カラム名・型に揃える
    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "level"
      type = "string"
    }
    columns {
      name = "request_id"
      type = "string"
    }
    columns {
      name = "client_ip"
      type = "string"
    }
    columns {
      name = "http_method"
      type = "string"
    }
    columns {
      name = "api_path"
      type = "string"
    }
    columns {
      name = "status_code"
      type = "int"
    }
    columns {
      name = "response_time_ms"
      type = "int"
    }
    columns {
      name = "request_body"
      type = "struct<order_id:string,instrument:string,order_type:string,quantity:int,price:double,side:string>"
    }
    columns {
      name = "auth_method"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "note"
      type = "string"
    }
    columns {
      name = "environment"
      type = "string"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "ecs_cluster"
      type = "string"
    }
    columns {
      name = "ecs_service"
      type = "string"
    }
    columns {
      name = "ecs_task_id"
      type = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "string"
  }

  partition_keys {
    name = "month"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }
}

# S3 Express One Zone/Parquet
resource "aws_glue_catalog_table" "api_logs_parquet_express" {
  name          = "${var.project_name}-api-logs-parquet-express"
  database_name = aws_glue_catalog_database.builders_flash_logs.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification"            = "parquet"
    "typeOfData"                = "file"
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2024,2026"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "projection.month.digits"   = "2"
    "projection.day.type"       = "integer"
    "projection.day.range"      = "1,31"
    "projection.day.digits"     = "2"
    "storage.location.template" = "s3://${aws_s3_directory_bucket.api_logs_parquet_express.bucket}/api-logs-parquet/year=$${year}/month=$${month}/day=$${day}"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_directory_bucket.api_logs_parquet_express.bucket}/api-logs-parquet/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "level"
      type = "string"
    }
    columns {
      name = "request_id"
      type = "string"
    }
    columns {
      name = "client_ip"
      type = "string"
    }
    columns {
      name = "http_method"
      type = "string"
    }
    columns {
      name = "api_path"
      type = "string"
    }
    columns {
      name = "status_code"
      type = "int"
    }
    columns {
      name = "response_time_ms"
      type = "int"
    }
    columns {
      name = "request_body"
      type = "struct<order_id:string,instrument:string,order_type:string,quantity:int,price:double,side:string>"
    }
    columns {
      name = "auth_method"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "note"
      type = "string"
    }
    columns {
      name = "environment"
      type = "string"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "ecs_cluster"
      type = "string"
    }
    columns {
      name = "ecs_service"
      type = "string"
    }
    columns {
      name = "ecs_task_id"
      type = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "string"
  }

  partition_keys {
    name = "month"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }
}

# Iceberg形式のAPIログテーブル（既存データベースを使用）
resource "aws_glue_catalog_table" "api_logs_iceberg" {
  name          = "${var.project_name}-api-logs-iceberg"
  database_name = aws_glue_catalog_database.builders_flash_logs.name
  description   = "API logs in Iceberg table format"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "table_type"                      = "ICEBERG"
    "format"                          = "iceberg"
    "write.format.default"            = "parquet"
    "write.parquet.compression-codec" = "gzip"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.api_logs_iceberg.id}/warehouse/builders_flash_logs.db/api_logs_iceberg/data/"
    input_format  = "org.apache.iceberg.mr.mapred.MapredIcebergInputFormat"
    output_format = "org.apache.iceberg.mr.mapred.MapredIcebergOutputFormat"

    ser_de_info {
      name                  = "iceberg.mr.mapred.MapredIcebergSerDe"
      serialization_library = "org.apache.iceberg.mr.mapred.MapredIcebergSerDe"
    }

    # APIログのスキーマ定義
    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "level"
      type = "string"
    }
    columns {
      name = "request_id"
      type = "string"
    }
    columns {
      name = "client_ip"
      type = "string"
    }
    columns {
      name = "http_method"
      type = "string"
    }
    columns {
      name = "api_path"
      type = "string"
    }
    columns {
      name = "status_code"
      type = "int"
    }
    columns {
      name = "response_time_ms"
      type = "int"
    }
    columns {
      name = "request_body"
      type = "struct<order_id:string,instrument:string,order_type:string,quantity:int,price:double,side:string>"
    }
    columns {
      name = "auth_method"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "note"
      type = "string"
    }
    columns {
      name = "environment"
      type = "string"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "ecs_cluster"
      type = "string"
    }
    columns {
      name = "ecs_service"
      type = "string"
    }
    columns {
      name = "ecs_task_id"
      type = "string"
    }
  }
}

# Terraform内に直接Glueスクリプトを記述
locals {
  glue_script = <<-EOT
import sys
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions

# 引数取得
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

# Spark/Glue セットアップ
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

print("Starting Parquet to Iceberg conversion...")

# ParquetデータをS3から読み込み
print("Reading Parquet data from S3...")
df = spark.read.parquet("s3://${aws_s3_bucket.api_logs_parquet.id}/api-logs-parquet/")

# データ件数を確認
record_count = df.count()
print(f"Processing {record_count} records")

# IcebergテーブルにデータをAppend（初回でも自動でテーブル作成）
print("Writing data to Iceberg table...")
df.write \
  .format("iceberg") \
  .mode("append") \
  .option("write.format.default", "parquet") \
  .option("write.parquet.compression-codec", "snappy") \
  .saveAsTable("glue_catalog.builders_flash_logs.api_logs_iceberg")

print("Parquet to Iceberg conversion completed successfully")

job.commit()
EOT
}

# GlueスクリプトをS3オブジェクトとして作成
resource "aws_s3_object" "parquet_to_iceberg_script" {
  bucket = aws_s3_bucket.glue_scripts.id
  key    = "scripts/parquet_to_iceberg.py"

  content      = local.glue_script
  content_type = "text/plain"

  tags = {
    Name    = "${var.project_name}-parquet-to-iceberg-script"
    Purpose = "Convert Parquet data to Iceberg table"
  }
}

# Glue Job作成（ParquetからIcebergへの変換）
resource "aws_glue_job" "parquet_to_iceberg" {
  name     = "${var.project_name}-parquet-to-iceberg"
  role_arn = aws_iam_role.glue_service_role.arn

  glue_version      = "4.0"
  max_retries       = 0
  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = 2880

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${aws_s3_bucket.glue_scripts.id}/${aws_s3_object.parquet_to_iceberg_script.key}"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-glue-datacatalog"          = "true"
    "--datalake-formats"                 = "iceberg"
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = "s3://${aws_s3_bucket.glue_scripts.id}/spark-logs/"
    "--conf"                             = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.warehouse=s3://${aws_s3_bucket.api_logs_iceberg.id}/warehouse/ --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO --conf spark.serializer=org.apache.spark.serializer.KryoSerializer"
  }
}
