#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------
# 共通変数
# ---------------------------------------------------
REGION=ap-northeast-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Git の現在のコミットを短縮形式で取得
GIT_HASH=$(git rev-parse --short HEAD)

# ECRへログイン（最初に一度だけでOK）
aws ecr get-login-password \
  --region ${REGION} \
| docker login --username AWS --password-stdin ${ECR_REGISTRY}

# ターゲットとするサービス名のリスト
SERVICES=( api-service )

for svc in "${SERVICES[@]}"; do
  IMAGE_NAME=${ECR_REGISTRY}/${svc}

  echo "=== Building and tagging ${svc} ==="

  # Docker イメージをビルド → latest と GIT_HASH の２つのタグを同時に付与
  docker build \
    --platform=linux/amd64 \
    -t ${svc}:latest \
    -t ${IMAGE_NAME}:latest \
    -t ${IMAGE_NAME}:${GIT_HASH} \
    ${svc}/   # 各サービスの Dockerfile が配置されたディレクトリ

  # latest タグをプッシュ
  docker push ${IMAGE_NAME}:latest

  # ハッシュタグをプッシュ
  docker push ${IMAGE_NAME}:${GIT_HASH}

  echo "=== Pushed ${svc}:latest and ${svc}:${GIT_HASH} ==="
done

# 新しいデプロイの強制
aws ecs update-service \
  --cluster buildersflash-cluster \
  --service api-service \
  --force-new-deployment
