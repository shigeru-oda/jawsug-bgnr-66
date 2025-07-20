#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------
# 共通変数
# ---------------------------------------------------
REGION=ap-northeast-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# ECR関連の変数
API_REPOSITORY_NAME="buildersflash-api-service"

# BuildKit設定
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain

# Git の現在のコミットを短縮形式で取得
GIT_HASH=$(git rev-parse --short HEAD)
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ---------------------------------------------------
# 認証トークン取得
# ---------------------------------------------------
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# ---------------------------------------------------
# API Service のビルド
# ---------------------------------------------------
API_IMAGE_NAME=${ECR_REGISTRY}/${API_REPOSITORY_NAME}
LOCAL_API_IMAGE_NAME=api-service

echo "=== Building API Service with BuildKit ==="

docker buildx create --name mybuilder --use --bootstrap 2>/dev/null || true

if ! docker buildx build \
  --platform=linux/amd64 \
  --cache-from=type=local,src=/tmp/.buildx-cache \
  --cache-to=type=local,dest=/tmp/.buildx-cache-new,mode=max \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --build-arg GIT_HASH="${GIT_HASH}" \
  --build-arg VERSION="${GIT_HASH}" \
  --label "org.opencontainers.image.created=${BUILD_DATE}" \
  --label "org.opencontainers.image.revision=${GIT_HASH}" \
  --label "org.opencontainers.image.source=https://github.com/your-org/jawsug-bgnr-66" \
  --label "org.opencontainers.image.title=API Service" \
  --label "org.opencontainers.image.version=${GIT_HASH}" \
  -t ${LOCAL_API_IMAGE_NAME}:latest \
  -t ${API_IMAGE_NAME}:latest \
  -t ${API_IMAGE_NAME}:${GIT_HASH} \
  --load \
  api-service/; then
    echo "❌ Error: API Service build failed"
    exit 1
fi

rm -rf /tmp/.buildx-cache
mv /tmp/.buildx-cache-new /tmp/.buildx-cache

echo "=== Pushing API Service images to ECR ==="

echo "Pushing ${API_IMAGE_NAME}:latest"
if ! docker push ${API_IMAGE_NAME}:latest; then
    echo "❌ Error: Failed to push API Service latest tag"
    exit 1
fi

echo "Pushing ${API_IMAGE_NAME}:${GIT_HASH}"
if ! docker push ${API_IMAGE_NAME}:${GIT_HASH}; then
    echo "❌ Error: Failed to push API Service hash tag"
    exit 1
fi

echo "✅ Successfully pushed api-service:latest and api-service:${GIT_HASH}"

echo ""
echo "🎉 ===== BUILD AND PUSH COMPLETED SUCCESSFULLY! ====="
echo "📦 API Service: ${API_IMAGE_NAME}:${GIT_HASH}"
echo "🚀 Architecture: Direct Firehose Integration"
echo "⚙️  Log Processing: API Service → Firehose (JSON + Parquet)"
echo "🔍 Build date: ${BUILD_DATE}"
echo "🚀 Next step: Run 'terraform apply' in the terraform directory to deploy"
echo ""
echo "📋 Deployment Commands:"
echo "  cd terraform"
echo "  terraform plan"
echo "  terraform apply"
echo ""
echo "🔍 Monitor logs with:"
echo "  aws logs tail /ecs/api-service --region ${REGION} --follow"
echo "=================================================="
