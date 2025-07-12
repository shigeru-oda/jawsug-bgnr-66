# AWS リソースのTerraform移行ガイド

## 📋 移行概要

ECSタスク定義やIAMポリシーなどのAWSリソース管理を、docker配下のJSONファイルからTerraform Infrastructure as Code (IaC) に移行しました。

## 🔄 主な変更点

### 1. **S3バケットの追加**
- **FireLens設定ファイル用バケット**: `${project_name}-firelens-config-${random_suffix}`
- **自動アップロード**: Fluent Bit設定ファイルを自動でS3にアップロード
- **バージョニング・暗号化**: セキュリティとガバナンス強化

### 2. **ECSタスク定義の最新化**
- **FireLensサイドカーパターン**: AWS推奨のアーキテクチャに更新
- **S3設定ファイル**: 設定の柔軟な管理が可能
- **ヘルスチェック**: アプリケーションの自動健全性監視
- **リソース最適化**: CPU・メモリ配分の効率化

### 3. **IAMポリシーの統合**
- **S3読み込み権限**: FireLens設定ファイル読み込み用
- **Firehose送信権限**: 2つのストリームへの送信権限
- **最小権限の原則**: セキュリティベストプラクティス準拠

### 4. **削除されたファイル**
```
docker/api-service/
├── ecs-task-definition-firelens.json      # ❌ 削除
├── ecs-task-definition-firelens-s3.json   # ❌ 削除
├── iam-policies.json                      # ❌ 削除
└── deploy-firelens.sh                     # ❌ 削除
```

## 🏗️ 新しいアーキテクチャ

### コンテナ構成
```
ECSタスク
├── log_router (FireLens)
│   ├── AWS公式Fluent Bitイメージ
│   ├── S3からカスタム設定読み込み
│   └── 2つのFirehoseに送信
└── api-service (アプリケーション)
    ├── FastAPIアプリケーション
    ├── ログをFireLensに送信
    └── ヘルスチェック機能
```

### データフロー
```
FastAPI App → FireLens → {api_logs_json, api_logs_parquet} → S3
            ↓
        CloudWatch Logs (FireLens自体のログ)
```

## 🚀 デプロイメント手順

### 1. **イメージのビルド・プッシュ**
```bash
cd docker
./ecr-push.sh
```

### 2. **Terraformでのデプロイ**
```bash
cd terraform

# 初回の場合は初期化
terraform init

# 変更内容の確認
terraform plan

# デプロイ実行
terraform apply
```

### 3. **設定の確認**
```bash
# ECSサービスの状態確認
aws ecs describe-services \
  --cluster buildersflash-cluster \
  --services api-service

# S3の設定ファイル確認
aws s3 ls s3://buildersflash-firelens-config-xxxxxxxx/fluent-bit/
```

## 📁 Terraform構成

### 新規追加されたリソース
```
terraform/
├── s3.tf              # FireLens設定バケット追加
├── iam.tf             # S3読み込み権限追加
└── ecs.tf             # タスク定義をFireLens対応に更新
```

### 主要リソース
- `aws_s3_bucket.firelens_config` - 設定ファイル用バケット
- `aws_s3_object.fluent_bit_config` - Fluent Bit設定ファイル
- `aws_iam_policy.firelens_s3_config_policy` - S3読み込み権限
- `aws_ecs_task_definition.api_service` - FireLens対応タスク定義

## 🔧 設定のカスタマイズ

### Fluent Bit設定の変更
```bash
# 設定ファイルを編集
vi docker/api-service/fluent-bit-firelens.conf

# Terraformで反映
terraform apply
```

### 環境変数の管理
```hcl
# terraform/ecs.tf内で管理
environment = [
  {
    name  = "AWS_REGION"
    value = var.aws_region
  },
  {
    name  = "FIREHOSE_STREAM_JSON"
    value = aws_kinesis_firehose_delivery_stream.api_logs_json.name
  }
]
```

## 🛡️ セキュリティ改善

### 実装されたセキュリティ対策
1. **最小権限IAMポリシー**: 必要最小限の権限のみ付与
2. **S3バケット暗号化**: AES256による保存時暗号化
3. **バージョニング**: 設定ファイルの変更履歴追跡
4. **Terraformステート管理**: インフラの変更追跡

## 📊 監視とトラブルシューティング

### ログの確認
```bash
# FireLensコンテナのログ
aws logs tail /ecs/buildersflash-cluster --follow \
  --filter-pattern "firelens"

# アプリケーションのログ（Firehose経由）
# S3バケットまたはCloudWatch Insightsで確認
```

### よくある問題
1. **S3権限エラー**: IAMロールにS3読み込み権限があるか確認
2. **Firehose送信エラー**: タスクロールにFirehose権限があるか確認
3. **設定ファイルエラー**: S3の設定ファイルが正しくアップロードされているか確認

## 🔄 ロールバック手順

問題が発生した場合：
```bash
# 前回の安定版タスク定義に戻す
aws ecs update-service \
  --cluster buildersflash-cluster \
  --service api-service \
  --task-definition api-service:PREVIOUS_REVISION

# またはTerraformで前回の状態に戻す
terraform apply -target=aws_ecs_task_definition.api_service
```

## 💡 今後の改善点

### 短期的改善
1. **Blue/Greenデプロイ**: CodeDeployとの統合
2. **自動スケーリング**: CPU/メモリベースのオートスケーリング
3. **アラート設定**: CloudWatch Alarmsでの監視強化

### 長期的改善
1. **マルチリージョン対応**: 災害復旧体制の構築
2. **コスト最適化**: Fargate Spotの活用
3. **セキュリティ強化**: AWS Config Rulesでのコンプライアンス監視

---

**移行完了日**: 2025年1月12日  
**移行者**: AI Assistant  
**バージョン**: v2.0.0 