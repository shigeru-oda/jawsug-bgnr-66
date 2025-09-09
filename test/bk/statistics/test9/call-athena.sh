#!/bin/bash

#==========================
# 設定
#==========================
DATABASE="buildersflash_buildersflash_logs"
REGION="ap-northeast-1"
WORKGROUP="buildersflash-api-logs"

TABLES=(
  "buildersflash_api_logs_iceberg_query"
  "buildersflash_api_logs_json"
  "buildersflash_api_logs_json_gz"
  "buildersflash_api_logs_parquet"
)

RUN_COUNT=10

#==========================
# SQLテンプレート
# {TABLE_NAME} を対象テーブルに置換して使用
#==========================
read -r -d '' SQL_TEMPLATE <<'EOSQL'
WITH top_ips AS (
    SELECT client_ip, COUNT(*) AS request_count
    FROM {TABLE_NAME}
    WHERE year = '2025' AND month = '07' AND day BETWEEN '01' AND '07'
    GROUP BY client_ip
    ORDER BY request_count DESC
    LIMIT 50
)
SELECT
    t.client_ip,
    t.request_count,
    AVG(l.response_time_ms) AS avg_response_time,
    MAX(l.response_time_ms) AS peak_response_time,
    COUNT(DISTINCT l.status_code) AS status_variation
FROM top_ips t
JOIN {TABLE_NAME} l
  ON t.client_ip = l.client_ip
  AND l.year = '2025' AND l.month = '07' AND l.day BETWEEN '01' AND '07'
GROUP BY t.client_ip, t.request_count
ORDER BY t.request_count DESC;
EOSQL

# CSVファイル
DETAIL_CSV="athena_exec_times_detail.csv"
SUMMARY_CSV="athena_exec_times_summary.csv"

# ヘッダー行を初期化（スキャンデータ量MB追加）
echo "table,run,execution_time_sec,data_scanned_mb" > "$DETAIL_CSV"
echo "table,avg_execution_time_sec,avg_data_scanned_mb" > "$SUMMARY_CSV"

#==========================
# 実行
#==========================
for table in "${TABLES[@]}"; do
  echo "=== Table: $table ==="
  total_time=0
  total_scanned=0

  for ((i=1; i<=RUN_COUNT; i++)); do
    SQL="${SQL_TEMPLATE//\{TABLE_NAME\}/$table}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executing ($i/$RUN_COUNT) ..."

    # クエリ実行 → 実行ID取得
    QUERY_EXEC_ID=$(aws athena start-query-execution \
      --query-string "$SQL" \
      --query-execution-context Database="$DATABASE" \
      --work-group "$WORKGROUP" \
      --region "$REGION" \
      --query 'QueryExecutionId' \
      --output text)

    # 完了待ち
    while true; do
      STATUS=$(aws athena get-query-execution \
        --query-execution-id "$QUERY_EXEC_ID" \
        --region "$REGION" \
        --query 'QueryExecution.Status.State' \
        --output text)

      if [[ "$STATUS" == "SUCCEEDED" ]]; then
        break
      elif [[ "$STATUS" == "FAILED" || "$STATUS" == "CANCELLED" ]]; then
        echo "Execution failed: $QUERY_EXEC_ID"
        break
      fi

      sleep 1
    done

    # 実行時間とスキャンデータ量を取得
    DURATION_MS=$(aws athena get-query-execution \
      --query-execution-id "$QUERY_EXEC_ID" \
      --region "$REGION" \
      --query 'QueryExecution.Statistics.EngineExecutionTimeInMillis' \
      --output text)

    SCANNED_BYTES=$(aws athena get-query-execution \
      --query-execution-id "$QUERY_EXEC_ID" \
      --region "$REGION" \
      --query 'QueryExecution.Statistics.DataScannedInBytes' \
      --output text)

    # 秒とMBに変換
    DURATION_SEC=$(awk "BEGIN {print $DURATION_MS/1000}")
    SCANNED_MB=$(awk "BEGIN {print $SCANNED_BYTES/1024/1024}")

    echo "Execution time: ${DURATION_SEC}s, Data scanned: ${SCANNED_MB}MB"

    # CSVに記録
    echo "$table,$i,$DURATION_SEC,$SCANNED_MB" >> "$DETAIL_CSV"

    total_time=$(awk "BEGIN {print $total_time+$DURATION_SEC}")
    total_scanned=$(awk "BEGIN {print $total_scanned+$SCANNED_MB}")
  done

  avg_time=$(awk "BEGIN {print $total_time/$RUN_COUNT}")
  avg_scanned=$(awk "BEGIN {print $total_scanned/$RUN_COUNT}")

  echo "Average execution time for $table: ${avg_time}s, Avg data scanned: ${avg_scanned}MB"
  echo "$table,$avg_time,$avg_scanned" >> "$SUMMARY_CSV"
  echo
done

echo "=== Completed ==="
echo "詳細: $DETAIL_CSV"
echo "平均: $SUMMARY_CSV"
