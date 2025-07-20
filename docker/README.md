# ログ送信フロー

```
FastAPI Application
       ↓ Direct boto3 API calls
Kinesis Firehose (2 streams)
       ├── buildersflash-api-service-json → S3 (JSON bucket)
       └── buildersflash-api-service-parquet → S3 (Parquet bucket)
```

# ALB_DNSを取得
ALB_DNS=$(aws elbv2 describe-load-balancers --names buildersflash-api-service --region ap-northeast-1 --query 'LoadBalancers[0].DNSName' --output text)
echo $ALB_DNS

# CURL
curl http://${ALB_DNS}
curl http://${ALB_DNS}/health
