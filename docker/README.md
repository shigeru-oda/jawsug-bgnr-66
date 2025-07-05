# Docker コンテナ

## ECRへのPUSH方法

### HASH取得
GIT_HASH=$(git rev-parse --short HEAD)

### api-service
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com
docker build --platform=linux/amd64 -t api-service .
docker tag api-service:latest 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/api-service:latest
docker tag api-service:latest 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/api-service:$GIT_HASH
docker push 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/api-service:latest

### fluent-bit
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com
docker build --platform=linux/amd64 -t fluent-bit .
docker tag fluent-bit:latest 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/fluent-bit:latest
docker tag fluent-bit:latest 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/fluent-bit:$GIT_HASH
docker push 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/fluent-bit:latest

## API エンドポイント使用例

### 1. ヘルスチェック

```bash
curl -X GET http://localhost:8000/health
```

レスポンス例:
```json
{
  "status": "healthy"
}
```

### 2. 単一注文作成 (/api/v1/orders)

```bash
curl -X POST http://localhost:8000/api/v1/orders \
  -H "Content-Type: application/json" \
  -H "X-User-ID: user-123" \
  -d '{"item_id": "item-abc"}'
```

レスポンス例:
```json
{
  "order_id": "a1b2c"
}
```

### 3. バッチ注文作成 (/api/v1/batch)

指定した回数分の注文をバッチ処理します。各リクエストにはランダムなユーザーIDとアイテムIDが生成されます。

```bash
curl -X POST http://localhost:8000/api/v1/batch \
  -H "Content-Type: application/json" \
  -d '{"count": 3}'
```

レスポンス例:
```json
{
  "results": [
    {"order_id": "a1b2c"},
    {"order_id": "d4e5f"},
    {"order_id": "g7h8i"}
  ]
}
```
