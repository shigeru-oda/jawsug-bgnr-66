#!/bin/bash

# S3バケット名を設定
JSON_S3_BUCKET_NAME="buildersflash-api-logs-json-gz-f17f6kjd"
BASE_PATH="api-logs-json-gz/year=2025/month=07/"

echo "S3バケット ${JSON_S3_BUCKET_NAME} のファイルリストを作成します..."

# ファイルリストを保存するディレクトリ
LIST_DIR="file_lists"
mkdir -p "$LIST_DIR"

# 各日のフォルダを確認
for day in {01..01}; do
    DAY_PATH="${BASE_PATH}day=$(printf "%02d" $day)/"
    
    echo "day=${day} のファイルを確認中..."
    
    # その日のファイル数を確認
    echo "  確認パス: s3://${JSON_S3_BUCKET_NAME}/${DAY_PATH}"
    FILE_COUNT=$(aws s3 ls s3://${JSON_S3_BUCKET_NAME}/${DAY_PATH} --recursive 2>/dev/null | wc -l)
    
    if [ $FILE_COUNT -gt 0 ]; then
        echo "day=${day}: ${FILE_COUNT}個のファイルを発見"
        
        # ファイル一覧を取得してリストファイルに保存
        LIST_FILE="${LIST_DIR}/day$(printf "%02d" $day)_files.txt"
        aws s3 ls s3://${JSON_S3_BUCKET_NAME}/${DAY_PATH} --recursive > "$LIST_FILE" 2>/dev/null
        
        if [ -s "$LIST_FILE" ]; then
            echo "  ファイルリストを作成: ${LIST_FILE}"
            
            # ファイル一覧の最初の5個を表示
            echo "  最初の5個のファイル:"
            head -5 "$LIST_FILE" | while read -r line; do
                filename=$(echo "$line" | awk '{print $4}')
                size=$(echo "$line" | awk '{print $3}')
                echo "    - ${filename} (${size} bytes)"
            done
            
            if [ $FILE_COUNT -gt 5 ]; then
                echo "    ... 他 $((FILE_COUNT - 5))個のファイル"
            fi
        else
            echo "  day=${day} のファイル一覧取得に失敗しました"
        fi
    else
        echo "day=${day}: ファイルなし"
        echo "  試行: aws s3 ls s3://${JSON_S3_BUCKET_NAME}/${DAY_PATH} --recursive"
        # エラー出力も表示
        aws s3 ls s3://${JSON_S3_BUCKET_NAME}/${DAY_PATH} --recursive 2>&1 | head -3
    fi
    
    echo ""
done

# 全体の統計を表示
echo "=== 全体の統計 ==="
TOTAL_FILES=0
FOLDERS_WITH_FILES=0

for day in {01..31}; do
    LIST_FILE="${LIST_DIR}/day$(printf "%02d" $day)_files.txt"
    if [ -f "$LIST_FILE" ]; then
        FILE_COUNT=$(wc -l < "$LIST_FILE")
        TOTAL_FILES=$((TOTAL_FILES + FILE_COUNT))
        FOLDERS_WITH_FILES=$((FOLDERS_WITH_FILES + 1))
        echo "day=$(printf "%02d" $day): ${FILE_COUNT}個のファイル"
    fi
done

echo ""
echo "ファイルがあるフォルダ数: ${FOLDERS_WITH_FILES}"
echo "総ファイル数: ${TOTAL_FILES}"
echo "ファイルリスト保存先: ${LIST_DIR}/"

echo "完了しました。"
