#!/bin/bash

# S3バケット名を設定
JSON_S3_BUCKET_NAME="buildersflash-api-logs-json-gz-f17f6kjd"
LIST_DIR="file_lists"

echo "ファイルリストを使ってS3バケット内のファイルを50倍に増幅します（並列処理版）..."

# ログファイルを設定
LOG_FILE="expansion_parallel_log_$(date +%Y%m%d_%H%M%S).log"

echo "ログファイル: ${LOG_FILE}"

# ログ関数
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ファイルリストディレクトリの確認
if [ ! -d "$LIST_DIR" ]; then
    log_message "エラー: ファイルリストディレクトリ ${LIST_DIR} が見つかりません"
    log_message "まず create_file_list.sh を実行してください"
    exit 1
fi

log_message "=== ファイルリストを使用した50倍増幅開始（並列処理版） ==="

# 各日のファイルリストを処理
for day in {01..31}; do
    LIST_FILE="${LIST_DIR}/day$(printf "%02d" $day)_files.txt"
    
    if [ -f "$LIST_FILE" ]; then
        FILE_COUNT=$(wc -l < "$LIST_FILE")
        log_message "day=$(printf "%02d" $day) のファイルリストを処理中: ${FILE_COUNT}個のファイル"
        
        # ファイルリストを読み込んで並列処理
        while IFS= read -r line; do
            # ファイルサイズとパスを抽出
            source_file=$(echo "$line" | awk '{print $4}')
            
            if [ -n "$source_file" ]; then
                log_message "  ファイル ${source_file} を50倍に増幅中（並列処理）..."
                
                # 2番目から50番目までコピー（1番目は元のファイル）
                for copy_num in {2..50}; do
                    # 新しいファイル名を生成（-01, -02, ..., -50の形式）
                    new_filename="${source_file}-$(printf "%02d" $copy_num)"
                    
                    # S3コピー（バックグラウンドで実行）
                    aws s3 cp "s3://${JSON_S3_BUCKET_NAME}/${source_file}" "s3://${JSON_S3_BUCKET_NAME}/${new_filename}" >/dev/null 2>&1 &
                    
                    # 同時実行数を制限（50個まで）
                    job_count=$(jobs -r | wc -l)
                    while [ $job_count -ge 50 ]; do
                        sleep 1
                        job_count=$(jobs -r | wc -l)
                    done
                done
            fi
        done < "$LIST_FILE"
        
        # この日の処理が完了するまで待機
        log_message "  day=$(printf "%02d" $day) の並列処理を待機中..."
        wait
        
        # 増設後のファイル数を確認
        DAY_PATH=$(head -1 "$LIST_FILE" | awk '{print $4}' | sed 's|/[^/]*$||')
        NEW_FILE_COUNT=$(aws s3 ls s3://${JSON_S3_BUCKET_NAME}/${DAY_PATH}/ --recursive 2>/dev/null | wc -l)
        EXPECTED_COUNT=$((FILE_COUNT * 50))
        
        log_message "day=$(printf "%02d" $day) 増設完了:"
        log_message "  元のファイル数: ${FILE_COUNT}"
        log_message "  増設後のファイル数: ${NEW_FILE_COUNT}"
        log_message "  期待されるファイル数: ${EXPECTED_COUNT}"
        
        if [ $NEW_FILE_COUNT -eq $EXPECTED_COUNT ]; then
            log_message "  ✅ day=${day} の50倍増設が正常に完了しました！"
        else
            log_message "  ⚠️  day=${day} のファイル数が期待値と異なります"
        fi
    else
        log_message "day=$(printf "%02d" $day): ファイルリストが見つかりません"
    fi
    
    log_message ""
done

# 全体の統計を表示
log_message "=== 全体の統計 ==="
TOTAL_ORIGINAL=0
TOTAL_NEW=0

for day in {01..31}; do
    LIST_FILE="${LIST_DIR}/day$(printf "%02d" $day)_files.txt"
    if [ -f "$LIST_FILE" ]; then
        ORIGINAL_COUNT=$(wc -l < "$LIST_FILE")
        DAY_PATH=$(head -1 "$LIST_FILE" | awk '{print $4}' | sed 's|/[^/]*$||')
        NEW_COUNT=$(aws s3 ls s3://${JSON_S3_BUCKET_NAME}/${DAY_PATH}/ --recursive 2>/dev/null | wc -l)
        TOTAL_ORIGINAL=$((TOTAL_ORIGINAL + ORIGINAL_COUNT))
        TOTAL_NEW=$((TOTAL_NEW + NEW_COUNT))
        log_message "day=$(printf "%02d" $day): 元${ORIGINAL_COUNT}個 → 現在${NEW_COUNT}個"
    fi
done

log_message ""
log_message "総計: 元${TOTAL_ORIGINAL}個 → 現在${TOTAL_NEW}個"

log_message "完了しました。"
echo ""
echo "ログファイル: ${LOG_FILE}"
