#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------
# 共通変数
# ---------------------------------------------------
REGION=ap-northeast-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# ECR関連の変数
API_REPOSITORY_NAME="api-service"
FLUENT_BIT_REPOSITORY_NAME="fluent-bit"

# BuildKit設定
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain

# Git の現在のコミットを短縮形式で取得
GIT_HASH=$(git rev-parse --short HEAD)
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ECRへログイン
echo "=== Logging into ECR ==="
aws ecr get-login-password \
  --region ${REGION} \
| docker login --username AWS --password-stdin ${ECR_REGISTRY}

# api-serviceイメージのビルドとタグ付け
API_IMAGE_NAME=${ECR_REGISTRY}/${API_REPOSITORY_NAME}
LOCAL_API_IMAGE_NAME=api-service

echo "=== Building api-service with BuildKit ==="

# BuildKitを使用したマルチプラットフォームビルド
docker buildx create --name mybuilder --use --bootstrap 2>/dev/null || true

# 効率的なビルド（キャッシュ活用）
docker buildx build \
  --platform=linux/amd64 \
  --cache-from=type=local,src=/tmp/.buildx-cache \
  --cache-to=type=local,dest=/tmp/.buildx-cache-new,mode=max \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --build-arg GIT_HASH="${GIT_HASH}" \
  --build-arg VERSION="${GIT_HASH}" \
  --label "org.opencontainers.image.created=${BUILD_DATE}" \
  --label "org.opencontainers.image.revision=${GIT_HASH}" \
  --label "org.opencontainers.image.source=https://github.com/your-org/your-repo" \
  --label "org.opencontainers.image.title=API Service" \
  --label "org.opencontainers.image.version=${GIT_HASH}" \
  -t ${LOCAL_API_IMAGE_NAME}:latest \
  -t ${API_IMAGE_NAME}:latest \
  -t ${API_IMAGE_NAME}:${GIT_HASH} \
  --load \
  api-service/

# キャッシュの更新
rm -rf /tmp/.buildx-cache
mv /tmp/.buildx-cache-new /tmp/.buildx-cache

echo "=== Pushing API Service images to ECR ==="

# latestタグをプッシュ
echo "Pushing ${API_IMAGE_NAME}:latest"
docker push ${API_IMAGE_NAME}:latest

# ハッシュタグをプッシュ
echo "Pushing ${API_IMAGE_NAME}:${GIT_HASH}"
docker push ${API_IMAGE_NAME}:${GIT_HASH}

echo "=== Successfully pushed api-service:latest and api-service:${GIT_HASH} ==="

# Fluent Bitイメージのビルドとタグ付け
FLUENT_BIT_IMAGE_NAME=${ECR_REGISTRY}/${FLUENT_BIT_REPOSITORY_NAME}
LOCAL_FLUENT_BIT_IMAGE_NAME=fluent-bit

echo "=== Building fluent-bit with BuildKit ==="

# Fluent Bitのビルド
docker buildx build \
  --platform=linux/amd64 \
  --cache-from=type=local,src=/tmp/.buildx-cache-fluent-bit \
  --cache-to=type=local,dest=/tmp/.buildx-cache-fluent-bit-new,mode=max \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --build-arg GIT_HASH="${GIT_HASH}" \
  --label "org.opencontainers.image.created=${BUILD_DATE}" \
  --label "org.opencontainers.image.revision=${GIT_HASH}" \
  --label "org.opencontainers.image.source=https://github.com/your-org/your-repo" \
  --label "org.opencontainers.image.title=Custom Fluent Bit" \
  --label "org.opencontainers.image.version=${GIT_HASH}" \
  -t ${LOCAL_FLUENT_BIT_IMAGE_NAME}:latest \
  -t ${FLUENT_BIT_IMAGE_NAME}:latest \
  -t ${FLUENT_BIT_IMAGE_NAME}:${GIT_HASH} \
  --load \
  fluent-bit/

# Fluent Bitキャッシュの更新
rm -rf /tmp/.buildx-cache-fluent-bit
mv /tmp/.buildx-cache-fluent-bit-new /tmp/.buildx-cache-fluent-bit

echo "=== Pushing Fluent Bit images to ECR ==="

# latestタグをプッシュ
echo "Pushing ${FLUENT_BIT_IMAGE_NAME}:latest"
docker push ${FLUENT_BIT_IMAGE_NAME}:latest

# ハッシュタグをプッシュ
echo "Pushing ${FLUENT_BIT_IMAGE_NAME}:${GIT_HASH}"
docker push ${FLUENT_BIT_IMAGE_NAME}:${GIT_HASH}

echo "=== Successfully pushed fluent-bit:latest and fluent-bit:${GIT_HASH} ==="

# イメージの脆弱性スキャン（ECR基本スキャン）
echo "=== Triggering ECR image scans ==="

# API Serviceのスキャン
aws ecr start-image-scan \
  --registry-id ${ACCOUNT_ID} \
  --repository-name ${API_REPOSITORY_NAME} \
  --image-id imageTag=latest \
  --region ${REGION} \
  2>/dev/null || echo "API Service image scan already in progress or not available"

# Fluent Bitのスキャン
aws ecr start-image-scan \
  --registry-id ${ACCOUNT_ID} \
  --repository-name ${FLUENT_BIT_REPOSITORY_NAME} \
  --image-id imageTag=latest \
  --region ${REGION} \
  2>/dev/null || echo "Fluent Bit image scan already in progress or not available"

# 実行完了の通知
echo "✅ Build and push completed successfully!"
echo "📦 API Service: ${API_IMAGE_NAME}:${GIT_HASH}"
echo "📦 Fluent Bit: ${FLUENT_BIT_IMAGE_NAME}:${GIT_HASH}"
echo "🔍 Build date: ${BUILD_DATE}"
echo "🚀 Next step: Run 'terraform apply' in the terraform directory to deploy"
