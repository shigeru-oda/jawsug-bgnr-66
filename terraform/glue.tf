resource "aws_glue_catalog_database" "api_logs_database" {
  name = "builders_flash_logs"
}
# S3 Standard/JSON+GZIP圧縮
resource "aws_glue_catalog_table" "api_logs_json_table" {
  name          = "api_logs_json"
  database_name = aws_glue_catalog_database.api_logs_database.name

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
resource "aws_glue_catalog_table" "api_logs_parquet_table" {
  name          = "api_logs_parquet"
  database_name = aws_glue_catalog_database.api_logs_database.name

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
resource "aws_glue_catalog_table" "api_logs_json_express_table" {
  name          = "api_logs_json_express"
  database_name = aws_glue_catalog_database.api_logs_database.name

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
resource "aws_glue_catalog_table" "api_logs_parquet_express_table" {
  name          = "api_logs_parquet_express"
  database_name = aws_glue_catalog_database.api_logs_database.name

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
