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

### S3 上のデータ調査

#### json

- 1 日辺り、91 ファイル（非圧縮）
- 最小サイズ 4.1KB
- 最大サイズ 13.1MB
- 合計サイズ 527.4MB
- これを 31 日分を用意 15.9GB

#### parquet

- 1 日辺り、91 ファイル
- 最小サイズ 4.7KB
- 最大サイズ 1.3MB
- 合計サイズ 52.6MB
- これを 31 日分を用意 1.5GB

#### iceberg

- 1 日辺り、11 ファイル
- 最小サイズ 2.8MB
- 最大サイズ 16.2MB
- 合計サイズ 63.5MB
- これを 31 日分を用意 1.9GB

### Athena での検索

以降は私のデータでの検索結果です。

#### SELECT count(\*) FROM TABLE;

|              | api_logs_json | api_logs_json_express | api_logs_parquet | api_logs_parquet_express | api_logs_iceberg |
| :----------- | :------------ | :-------------------- | :--------------- | :----------------------- | :--------------- |
| 実行時間１   | 2.985         | 4.646                 | 4.281            | 2.162                    | 1.523            |
| 実行時間２   | 4.135         | 4.619                 | 4.109            | 2.543                    | 1.783            |
| 実行時間３   | 3.217         | 5.527                 | 2.718            | 2.553                    | 1.645            |
| 実行時間４   | 3.717         | 3.797                 | 3.299            | 2.358                    | 1.162            |
| 実行時間５   | 3.613         | 9.164                 | 3.489            | 2.373                    | 1.659            |
| 実行時間６   | 3.247         | 4.523                 | 4.292            | 2.681                    | 1.681            |
| 実行時間７   | 2.871         | 3.855                 | 2.73             | 1.811                    | 1.427            |
| 実行時間８   | 2.854         | 3.251                 | 3.736            | 4.306                    | 1.752            |
| 実行時間９   | 3.627         | 5.361                 | 4.958            | 3.134                    | 1.109            |
| 実行時間１０ | 3.195         | 4.762                 | 5.84             | 2.58                     | 2.136            |
| 平均実行時間 | 3.3461        | 4.9505                | 3.9452           | 2.6501                   | 1.5877           |
| 比較         | 100%          | 148%                  | 118%             | 79%                      | 47%              |

#### SELECT count(region) FROM TABLE WHERE "region" = 'ap-northeast-1';

|              | api_logs_json | api_logs_json_express | api_logs_parquet | api_logs_parquet_express | api_logs_iceberg |
| :----------- | :------------ | :-------------------- | :--------------- | :----------------------- | :--------------- |
| 実行時間１   | 5.653         | 5.471                 | 2.783            | 2.763                    | 2.186            |
| 実行時間２   | 5.233         | 4.648                 | 2.908            | 3.415                    | 1.693            |
| 実行時間３   | 5.034         | 5.06                  | 4.201            | 2.644                    | 2.477            |
| 実行時間４   | 6.155         | 4.598                 | 2.776            | 2.899                    | 1.969            |
| 実行時間５   | 5.42          | 7.711                 | 3.305            | 2.711                    | 2.006            |
| 実行時間６   | 6.182         | 6.172                 | 2.687            | 2.465                    | 1.156            |
| 実行時間７   | 5.074         | 6.003                 | 3.136            | 2.906                    | 1.975            |
| 実行時間８   | 5.551         | 4.534                 | 3.125            | 2.732                    | 1.793            |
| 実行時間９   | 5.802         | 6.756                 | 3.107            | 2.664                    | 2.52             |
| 実行時間１０ | 7.545         | 6.631                 | 4.546            | 2.971                    | 2.159            |
| 平均実行時間 | 5.7649        | 5.7584                | 3.2574           | 2.817                    | 1.9934           |
| 比較         | 100%          | 100%                  | 57%              | 49%                      | 35%              |

#### SELECT count(day) FROM TABLE WHERE "year" = '2025' AND "month" = '07' AND "day" = '01';

|              | api_logs_json | api_logs_json_express | api_logs_parquet | api_logs_parquet_express | api_logs_iceberg |
| :----------- | :------------ | :-------------------- | :--------------- | :----------------------- | :--------------- |
| 実行時間１   | 0.838         | 1.235                 | 0.524            | 1.848                    | 1.499            |
| 実行時間２   | 0.696         | 2.562                 | 0.573            | 0.839                    | 1.687            |
| 実行時間３   | 0.784         | 1.071                 | 0.46             | 0.576                    | 1.535            |
| 実行時間４   | 0.63          | 2.999                 | 0.667            | 1.831                    | 1.054            |
| 実行時間５   | 0.778         | 1.464                 | 0.648            | 0.485                    | 3.047            |
| 実行時間６   | 0.709         | 1.323                 | 0.713            | 0.813                    | 0.987            |
| 実行時間７   | 0.918         | 1.421                 | 0.596            | 0.945                    | 3.205            |
| 実行時間８   | 0.807         | 2.134                 | 0.644            | 0.861                    | 1.455            |
| 実行時間９   | 1.755         | 1.476                 | 0.566            | 0.946                    | 2.436            |
| 実行時間１０ | 0.912         | 1.25                  | 0.677            | 0.85                     | 0.891            |
| 平均実行時間 | 0.8827        | 1.6935                | 0.6068           | 0.9994                   | 1.7796           |
| 比較         | 100%          | 192%                  | 69%              | 113%                     | 202%             |

#### SELECT count(request_body.instrument) FROM TABLE WHERE request_body.instrument = 'USDJPY';

|              | api_logs_json | api_logs_json_express | api_logs_parquet | api_logs_parquet_express | api_logs_iceberg |
| :----------- | :------------ | :-------------------- | :--------------- | :----------------------- | :--------------- |
| 実行時間１   | 5.208         | 5.88                  | 2.877            | 2.991                    | 1.685            |
| 実行時間２   | 7.72          | 5.141                 | 3.508            | 2.827                    | 1.371            |
| 実行時間３   | 6.324         | 4.954                 | 3.936            | 3.019                    | 1.29             |
| 実行時間４   | 5.335         | 8.083                 | 2.712            | 3.187                    | 1.905            |
| 実行時間５   | 6.275         | 9.283                 | 4.074            | 2.601                    | 1.356            |
| 実行時間６   | 5.385         | 10.568                | 3.235            | 2.779                    | 2.915            |
| 実行時間７   | 5.607         | 11.184                | 3.314            | 3.548                    | 2.832            |
| 実行時間８   | 6.006         | 5.919                 | 2.795            | 2.466                    | 1.552            |
| 実行時間９   | 5.25          | 6.253                 | 2.749            | 2.866                    | 1.695            |
| 実行時間１０ | 7.368         | 4.562                 | 4.504            | 2.896                    | 1.42             |
| 平均実行時間 | 6.0478        | 7.1827                | 3.3704           | 2.918                    | 1.8021           |
| 比較         | 100%          | 119%                  | 56%              | 48%                      | 30%              |

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
