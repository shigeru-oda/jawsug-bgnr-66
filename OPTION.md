# （オプション）データ拡張

### ECS の TASK 数を 0 に設定

```
aws ecs update-service \
  --cluster buildersflash-api-service \
  --service buildersflash-api-service \
  --desired-count 0
```

### データ拡張

約 50 万件のデータを用意していますので、データ拡張したい場合には以下データを利用下さい。
やりすぎるとコストに跳ねますのでご注意ください

```
# Localにダウンロード
curl -O https://d3ftdlmgxwxkod.cloudfront.net/api-logs-parquet.tar.gz
curl -O https://d1dd1f78xcaeij.cloudfront.net/api-logs-json.tar.gz

# 解凍・展開
tar -xzvf api-logs-parquet.tar.gz
tar -xzvf api-logs-json.tar.gz

# 削除
rm api-logs-parquet.tar.gz
rm api-logs-json.tar.gz

# フォルダ名を変数設定
PARQUET_S3_BUCKET_NAME="buildersflash-api-logs-parquet-f17f6kjd" # ここを更新
JSON_S3_BUCKET_NAME="buildersflash-api-logs-json-f17f6kjd" # ここを更新

# フォルダをS3にアップロード
aws s3 cp ./api-logs-parquet s3://${PARQUET_S3_BUCKET_NAME}/api-logs-parquet/year=2025/month=07/day=01/ --recursive
aws s3 cp s3://${PARQUET_S3_BUCKET_NAME}/api-logs-parquet/year=2025/month=07/day=01/ s3://${PARQUET_S3_BUCKET_NAME}/api-logs-parquet/year=2025/month=07/day=02/ --recursive
aws s3 cp s3://${PARQUET_S3_BUCKET_NAME}/api-logs-parquet/year=2025/month=07/day=01/ s3://${PARQUET_S3_BUCKET_NAME}/api-logs-parquet/year=2025/month=07/day=03/ --recursive
aws s3 cp s3://${PARQUET_S3_BUCKET_NAME}/api-logs-parquet/year=2025/month=07/day=01/ s3://${PARQUET_S3_BUCKET_NAME}/api-logs-parquet/year=2025/month=07/day=04/ --recursive
aws s3 cp s3://${PARQUET_S3_BUCKET_NAME}/api-logs-parquet/year=2025/month=07/day=01/ s3://${PARQUET_S3_BUCKET_NAME}/api-logs-parquet/year=2025/month=07/day=05/ --recursive
aws s3 cp s3://${PARQUET_S3_BUCKET_NAME}/api-logs-parquet/year=2025/month=07/day=01/ s3://${PARQUET_S3_BUCKET_NAME}/api-logs-parquet/year=2025/month=07/day=06/ --recursive

aws s3 cp ./api-logs-json s3://${JSON_S3_BUCKET_NAME}/api-logs-json/year=2025/month=07/day=01/ --recursive
aws s3 cp s3://${JSON_S3_BUCKET_NAME}/api-logs-json/year=2025/month=07/day=01/ s3://${JSON_S3_BUCKET_NAME}/api-logs-json/year=2025/month=07/day=02/ --recursive
aws s3 cp s3://${JSON_S3_BUCKET_NAME}/api-logs-json/year=2025/month=07/day=01/ s3://${JSON_S3_BUCKET_NAME}/api-logs-json/year=2025/month=07/day=03/ --recursive
aws s3 cp s3://${JSON_S3_BUCKET_NAME}/api-logs-json/year=2025/month=07/day=01/ s3://${JSON_S3_BUCKET_NAME}/api-logs-json/year=2025/month=07/day=04/ --recursive
aws s3 cp s3://${JSON_S3_BUCKET_NAME}/api-logs-json/year=2025/month=07/day=01/ s3://${JSON_S3_BUCKET_NAME}/api-logs-json/year=2025/month=07/day=05/ --recursive
aws s3 cp s3://${JSON_S3_BUCKET_NAME}/api-logs-json/year=2025/month=07/day=01/ s3://${JSON_S3_BUCKET_NAME}/api-logs-json/year=2025/month=07/day=06/ --recursive
```

### Athena での検索

以降は私のデータでの検索結果です。

#### SELECT count(\*) FROM TABLE;

|              | api_logs_json | api_logs_json_express | api_logs_parquet | api_logs_parquet_express | api_logs_iceberg |
| :----------- | :------------ | :-------------------- | :--------------- | :----------------------- | :--------------- |
| 件数         | 3,683,449     | 3,683,449             | 3,683,449        | 3,683,449                | 3,683,449        |
| 実行時間１   | 3.04          | 2.54                  | 2.66             | 2.01                     | 2.50             |
| 実行時間２   | 2.38          | 2.93                  | 2.89             | 2.13                     | 1.54             |
| 実行時間３   | 2.32          | 2.43                  | 2.35             | 2.24                     | 0.83             |
| 実行時間４   | 2.64          | 8.51                  | 2.40             | 1.60                     | 1.25             |
| 実行時間５   | 5.29          | 2.70                  | 2.32             | 2.37                     | 1.25             |
| 平均実行時間 | 3.13          | 3.82                  | 2.52             | 2.07                     | 1.47             |

#### SELECT count(\*) FROM TABLE WHERE "region" = 'ap-northeast-1';

|              | api_logs_json | api_logs_json_express | api_logs_parquet | api_logs_parquet_express | api_logs_iceberg |
| :----------- | :------------ | :-------------------- | :--------------- | :----------------------- | :--------------- |
| 件数         | 923,447       | 923,447               | 923,447          | 923,447                  | 923,447          |
| 実行時間１   | 5.59          | 3.33                  | 3.39             | 2.64                     | 1.76             |
| 実行時間２   | 5.04          | 5.38                  | 3.51             | 3.40                     | 3.46             |
| 実行時間３   | 4.63          | 4.71                  | 2.92             | 3.13                     | 2.28             |
| 実行時間４   | 3.80          | 5.43                  | 3.71             | 2.65                     | 1.70             |
| 実行時間５   | 4.32          | 5.74                  | 3.17             | 5.09                     | 1.97             |
| 平均実行時間 | 4.67          | 4.92                  | 3.34             | 3.38                     | 2.23             |

#### SELECT count(\*) FROM TABLE WHERE "year" = '2025' AND "month" = '07' AND "day" = '01';

|              | api_logs_json | api_logs_json_express | api_logs_parquet | api_logs_parquet_express | api_logs_iceberg |
| :----------- | :------------ | :-------------------- | :--------------- | :----------------------- | :--------------- |
| 件数         | 526,207       | 526,207               | 526,207          | 526,207                  | 526,207          |
| 実行時間１   | 0.70          | 1.59                  | 0.66             | 0.81                     | 1.52             |
| 実行時間２   | 0.63          | 2.05                  | 0.75             | 0.90                     | 0.91             |
| 実行時間３   | 0.72          | 1.32                  | 0.61             | 0.77                     | 0.88             |
| 実行時間４   | 0.83          | 1.38                  | 0.58             | 0.77                     | 2.26             |
| 実行時間５   | 0.81          | 1.37                  | 0.60             | 0.87                     | 2.02             |
| 平均実行時間 | 0.74          | 1.54                  | 0.64             | 0.82                     | 1.51             |

### buildersflash-glue-role に権限付与

Lake Formation -> Data permissions -> Grant
![](./img/img09.png)

### Glue で統計情報を取得

AWS Glue -> Tables -> テーブル名 -> Column statistics -> Generate statistics on demand -> All columns
Role は buildersflash-glue-role を選択してください

S3 Express One Zone は残念ながらサポート対象外です（のようです）

### Athena での検索（統計後）

#### SELECT count(\*) FROM TABLE;

|              | api_logs_json | api_logs_json_express | api_logs_parquet | api_logs_parquet_express | api_logs_iceberg |
| :----------- | :------------ | :-------------------- | :--------------- | :----------------------- | :--------------- |
| 件数         | 3,683,449     | -                     | 3,683,449        | -                        | 3,683,449        |
| 実行時間１   | 3.33          | -                     | 2.65             | -                        | 1.61             |
| 実行時間２   | 2.83          | -                     | 3.22             | -                        | 0.91             |
| 実行時間３   | 2.38          | -                     | 2.67             | -                        | 1.54             |
| 実行時間４   | 2.56          | -                     | 3.90             | -                        | 1.47             |
| 実行時間５   | 2.46          | -                     | 2.52             | -                        | 2.66             |
| 平均実行時間 | 2.71          | -                     | 2.99             | -                        | 1.64             |

#### SELECT count(\*) FROM TABLE WHERE "region" = 'ap-northeast-1';

|              | api_logs_json | api_logs_json_express | api_logs_parquet | api_logs_parquet_express | api_logs_iceberg |
| :----------- | :------------ | :-------------------- | :--------------- | :----------------------- | :--------------- |
| 件数         | 923,447       | -                     | 923,447          | -                        | 923,447          |
| 実行時間１   | 3.68          | -                     | 3.58             | -                        | 1.14             |
| 実行時間２   | 3.40          | -                     | 2.55             | -                        | 2.54             |
| 実行時間３   | 3.92          | -                     | 6.00             | -                        | 2.29             |
| 実行時間４   | 4.68          | -                     | 4.67             | -                        | 1.19             |
| 実行時間５   | 3.57          | -                     | 3.28             | -                        | 1.79             |
| 平均実行時間 | 3.85          | -                     | 4.01             | -                        | 1.79             |

#### SELECT count(\*) FROM TABLE WHERE "year" = '2025' AND "month" = '07' AND "day" = '01';

|              | api_logs_json | api_logs_json_express | api_logs_parquet | api_logs_parquet_express | api_logs_iceberg |
| :----------- | :------------ | :-------------------- | :--------------- | :----------------------- | :--------------- |
| 件数         | 526,207       | -                     | 526,207          | -                        | 526,207          |
| 実行時間１   | 0.95          | -                     | 0.74             | -                        | 1.58             |
| 実行時間２   | 1.04          | -                     | 0.76             | -                        | 1.51             |
| 実行時間３   | 0.83          | -                     | 0.64             | -                        | 0.97             |
| 実行時間４   | 1.03          | -                     | 0.77             | -                        | 2.27             |
| 実行時間５   | 1.08          | -                     | 0.66             | -                        | 0.88             |
| 平均実行時間 | 0.99          | -                     | 0.71             | -                        | 1.44             |
