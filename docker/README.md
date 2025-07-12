# Docker Images

このディレクトリには、以下のDockerイメージが含まれています：

## 📦 イメージ一覧

### 1. API Service (`api-service/`)
- **説明**: FastAPIベースのAPIサービス
- **機能**: ログ出力、ヘルスチェック、注文処理API
- **ベースイメージ**: python:3.13-slim

### 2. Fluent Bit (`fluent-bit/`)
- **説明**: 2つのFirehoseストリームに送信するカスタムFluent Bit
- **機能**: FireLens経由でJSONとParquet形式の両方のストリームに送信
- **ベースイメージ**: public.ecr.aws/aws-observability/aws-for-fluent-bit:stable

## 🚀 ビルド・デプロイ方法

### 前提条件
```bash
# AWS認証情報が設定されていること
aws configure list

# Dockerが起動していること
docker --version

# docker buildxがインストールされていること
docker buildx version
```

### イメージのビルドとプッシュ
```bash
# dockerディレクトリに移動
cd docker

# 両方のイメージをビルド・プッシュ
./ecr-push.sh
```

### スクリプトの機能
`ecr-push.sh`は以下を自動実行します：

1. **環境確認**
   - AWS認証情報の確認
   - BuildKit設定

2. **API Serviceイメージ**
   - BuildKitを使用した効率的ビルド
   - キャッシュ機能でビルド時間短縮
   - ECRへのプッシュ（latest + Git hash）

3. **Fluent Bitイメージ**
   - カスタム設定ファイル込みでビルド
   - ECRへのプッシュ（latest + Git hash）

4. **セキュリティ**
   - 両方のイメージに対する脆弱性スキャン実行

## 🔧 設定ファイル

### API Service設定
- `api-service/app/main.py`: メインアプリケーション
- `api-service/requirements.txt`: Python依存関係
- `api-service/Dockerfile`: イメージビルド設定

### Fluent Bit設定
- `fluent-bit/fluent-bit-multi-firehose.conf`: 2つのFirehose出力設定
- `fluent-bit/Dockerfile`: カスタムイメージビルド設定

## 📋 次のステップ

イメージのビルド・プッシュ完了後：

```bash
# Terraformディレクトリに移動
cd ../terraform

# インフラストラクチャをデプロイ
terraform apply
```

## 🔍 トラブルシューティング

### よくある問題

1. **ECR認証エラー**
   ```bash
   # ECRに再ログイン
   aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com
   ```

2. **BuildKitエラー**
   ```bash
   # BuildKitビルダーをリセット
   docker buildx rm mybuilder
   docker buildx create --name mybuilder --use --bootstrap
   ```

3. **キャッシュクリア**
   ```bash
   # ビルドキャッシュをクリア
   rm -rf /tmp/.buildx-cache*
   ```

## 📊 ログ送信フロー

```
FastAPI Application
       ↓ stdout/stderr
FireLens (Custom Fluent Bit)
       ├── OUTPUT 1 → buildersflash-api-logs-json
       └── OUTPUT 2 → builders-flash-api-logs-parquet
```
