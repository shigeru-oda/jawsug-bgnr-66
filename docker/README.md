# ログ送信フロー

```
FastAPI Application
       ↓ Direct boto3 API calls
Kinesis Firehose (4 streams)
       ├── buildersflash-api-service-json → S3 (JSON bucket, uncompressed)
       ├── buildersflash-api-service-json-gz → S3 (JSON bucket, GZIP compressed)
       ├── buildersflash-api-service-iceberg → S3 (Iceberg table, ACID transactions)
       └── buildersflash-api-service-parquet → S3 (Parquet bucket, optimized queries)
```

# ALB_DNSを取得
ALB_DNS=$(aws elbv2 describe-load-balancers --names buildersflash-api-service --region ap-northeast-1 --query 'LoadBalancers[0].DNSName' --output text)
echo $ALB_DNS

# CURL
curl http://${ALB_DNS}
curl http://${ALB_DNS}/health
