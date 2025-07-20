import json
import os
import random
import time
import uuid
import requests
from datetime import datetime
from typing import Dict, Any, Optional

import boto3
import uvicorn
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="API Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Firehose client initialization
firehose_client = boto3.client('firehose', region_name=os.environ.get('AWS_DEFAULT_REGION', 'ap-northeast-1'))

# Firehose stream names (from environment variables)
FIREHOSE_JSON_STREAM = os.environ.get('FIREHOSE_JSON_STREAM', 'api-service-json-firehose')
FIREHOSE_PARQUET_STREAM = os.environ.get('FIREHOSE_PARQUET_STREAM', 'api-service-parquet-firehose')

# Firehose送信関数
def send_to_firehose(json_data: Dict[str, Any], parquet_data: Optional[Dict[str, Any]] = None):
    """
    JSONとParquetの2つのFirehoseストリームに送信
    """
    try:
        # JSON Firehoseに送信
        json_record = json.dumps(json_data) + '\n'
        firehose_client.put_record(
            DeliveryStreamName=FIREHOSE_JSON_STREAM,
            Record={'Data': json_record}
        )
        
        # Parquet Firehoseに送信（構造化データ）
        if parquet_data:
            parquet_record = json.dumps(parquet_data) + '\n'
            firehose_client.put_record(
                DeliveryStreamName=FIREHOSE_PARQUET_STREAM,
                Record={'Data': parquet_record}
            )
        
        # コンソールにも出力（CloudWatch Logs用）
        print(json.dumps(json_data))
        
    except Exception as e:
        error_log = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": "ERROR",
            "service": "api-service",
            "message": f"Failed to send to Firehose: {str(e)}",
            "firehose_streams": {
                "json": FIREHOSE_JSON_STREAM,
                "parquet": FIREHOSE_PARQUET_STREAM
            }
        }
        print(json.dumps(error_log))

# --- ECSメタデータ取得関数 ---
def get_ecs_metadata():
    metadata = {
        "cluster": os.environ.get("ECS_CLUSTER_NAME", ""),
        "service": os.environ.get("ECS_SERVICE_NAME", ""),
        "task_id": ""
    }
    
    endpoint = os.environ.get("ECS_CONTAINER_METADATA_URI_V4")
    if endpoint:
        try:
            task_response = requests.get(f"{endpoint}/task", timeout=1)
            if task_response.status_code == 200:
                task_data = task_response.json()
                if "TaskARN" in task_data:
                    task_arn = task_data["TaskARN"]
                    task_id_parts = task_arn.split("/")
                    if len(task_id_parts) >= 3:
                        metadata["task_id"] = task_id_parts[-1]
                    if not metadata["cluster"] and len(task_id_parts) >= 2:
                        metadata["cluster"] = task_id_parts[-2]
                if not metadata["cluster"] and "Cluster" in task_data:
                    cluster_arn = task_data["Cluster"]
                    cluster_parts = cluster_arn.split("/")
                    if len(cluster_parts) >= 2:
                        metadata["cluster"] = cluster_parts[-1]
        except Exception as e:
            # 関数定義前のため一時的に従来形式
            metadata_log = {
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "level": "WARNING",
                "service": "api-service",
                "message": f"Failed to retrieve ECS metadata: {str(e)}"
            }
            print(json.dumps(metadata_log))
    
    if not metadata["cluster"]:
        metadata["cluster"] = os.environ.get("ECS_CLUSTER_NAME", "unknown-cluster")
    if not metadata["service"]:
        metadata["service"] = os.environ.get("ECS_SERVICE_NAME", "unknown-service")
    if not metadata["task_id"]:
        metadata["task_id"] = os.environ.get("ECS_TASK_ID", "unknown-task")
    
    return metadata

ecs_metadata = get_ecs_metadata()

# --- ランダムな認証・環境値を生成する関数 ---
def generate_random_values():
    auth_methods = ["BearerToken", "ApiKey", "OAuth2", "BasicAuth"]
    user_agents = [
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        "Mozilla/5.0 (X11; Linux x86_64)",
        "PostmanRuntime/7.32.3"
    ]
    environments = ["production", "staging", "development"]
    regions = ["ap-northeast-1", "us-east-1", "eu-west-1", "ap-southeast-1"]
    
    return {
        "auth_method": random.choice(auth_methods),
        "user_agent": random.choice(user_agents),
        "environment": random.choice(environments),
        "region": random.choice(regions)
    }

def generate_random_order_data():
    instruments = ["USDJPY", "EURJPY", "GBPJPY", "AUDJPY", "EURUSD"]
    order_types = ["LIMIT", "MARKET", "STOP", "STOP_LIMIT"]
    sides = ["BUY", "SELL"]
    
    return {
        "order_id": f"ORD-{random.randint(100000000, 999999999)}",
        "instrument": random.choice(instruments),
        "order_type": random.choice(order_types),
        "quantity": random.randint(10000, 1000000),
        "price": round(random.uniform(100.0, 200.0), 2),
        "side": random.choice(sides)
    }

# --- 統一ログフォーマット関数（メインHTTPログと同じ属性構造）---
def create_log_entry(
    level: str = "INFO",
    message: str = "",
    request_id: Optional[str] = None,
    user_id: Optional[str] = None,
    http_method: Optional[str] = None,
    api_path: Optional[str] = None,
    status_code: Optional[int] = None,
    response_time_ms: Optional[int] = None,
    client_ip: Optional[str] = None,
    request_body: Optional[Dict[str, Any]] = None,
    auth_method: Optional[str] = None,
    user_agent: Optional[str] = None,
    note: str = "",
    environment: Optional[str] = None,
    region: Optional[str] = None,
    ecs_cluster: Optional[str] = None,
    ecs_service: Optional[str] = None,
    ecs_task_id: Optional[str] = None,
    **additional_fields
) -> Dict[str, Any]:
    """
    メインHTTPログと同じ属性構造で統一されたログエントリを作成
    HTTPコンテキスト外では一部フィールドはデフォルト値を使用
    """
    # デフォルト値を生成
    random_values = generate_random_values()
    
    log_entry = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "level": level,
        "service": "api-service",
        "request_id": request_id or "",
        "user_id": user_id or "anonymous",
        "client_ip": client_ip or "",
        "http_method": http_method or "",
        "api_path": api_path or "",
        "status_code": status_code or 0,
        "response_time_ms": response_time_ms or 0,
        "request_body": request_body or {},
        "auth_method": auth_method or random_values.get("auth_method", "Unknown"),
        "user_agent": user_agent or random_values.get("user_agent", "Unknown"),
        "note": note,
        "message": message,
        "environment": environment or random_values.get("environment", "unknown"),
        "region": region or random_values.get("region", "ap-northeast-1"),
        "ecs_cluster": ecs_cluster or ecs_metadata.get("cluster", ""),
        "ecs_service": ecs_service or ecs_metadata.get("service", ""),
        "ecs_task_id": ecs_task_id or ecs_metadata.get("task_id", "")
    }
    
    # 追加フィールドをマージ
    log_entry.update(additional_fields)
    
    return log_entry

# --- 共通化された便利関数 ---
def log_and_send(level: str = "INFO", message: str = "", send_parquet: bool = True, **kwargs):
    """ログ作成とFirehose送信を一つにまとめた関数"""
    log_entry = create_log_entry(level=level, message=message, **kwargs)
    parquet_data = log_entry if send_parquet else None
    send_to_firehose(log_entry, parquet_data)
    return log_entry

def extract_request_info(request: Request) -> Dict[str, Any]:
    """HTTPリクエストから基本情報を抽出"""
    return {
        "request_id": str(uuid.uuid4()),
        "user_id": request.headers.get("X-User-ID", "anonymous"),
        "client_ip": request.client.host if request.client else "unknown",
        "http_method": request.method,
        "api_path": request.url.path
    }

def handle_error_with_log(error: Exception, context: str = "", request_id: str = ""):
    """エラー処理とログ出力を統合"""
    log_and_send(
        level="ERROR",
        message=f"Error in {context}: {str(error)}",
        request_id=request_id,
        error_context=context
    )

def generate_full_context() -> Dict[str, Any]:
    """ランダム値とECSメタデータを含む完全なコンテキストを生成"""
    random_values = generate_random_values()
    random_order = generate_random_order_data()
    
    return {
        **random_values,
        "request_body": random_order,
        "ecs_cluster": ecs_metadata.get("cluster"),
        "ecs_service": ecs_metadata.get("service"),
        "ecs_task_id": ecs_metadata.get("task_id")
    }

# --- 統一ログフォーマット関数定義後に初期ログを送信 ---
# 起動時ログとECSメタデータログを共通化関数で簡潔に送信
log_and_send(
    message="API Service starting up with direct Firehose integration",
    firehose_streams={"json": FIREHOSE_JSON_STREAM, "parquet": FIREHOSE_PARQUET_STREAM}
)

log_and_send(
    message="ECS metadata retrieved",
    ecs_metadata=ecs_metadata
)

# --- FastAPIのリクエストロギング用ミドルウェア ---
@app.middleware("http")
async def log_requests(request: Request, call_next):
    request_id = str(uuid.uuid4())
    request.state.request_id = request_id
    
    source_ip = request.client.host if request.client else "unknown"
    
    user_id = request.headers.get("X-User-ID", "anonymous")
    
    start_time = time.time()
    
    request_body = None
    if request.method in ["POST", "PUT", "PATCH"]:
        original_receive = request._receive
        
        body_bytes = b""
        
        async def receive_with_store():
            nonlocal body_bytes
            message = await original_receive()
            if message["type"] == "http.request":
                body_bytes += message.get("body", b"")
                message["more_body"] = False
            return message
        
        request._receive = receive_with_store
        
        response = await call_next(request)
        
        try:
            if body_bytes:
                request_body = json.loads(body_bytes)
        except Exception as e:
            handle_error_with_log(e, "parsing request body", request_id)
    else:
        response = await call_next(request)
    
    response_time_ms = int((time.time() - start_time) * 1000)
    
    response_body = None
    if hasattr(response, "body"):
        try:
            response_body_bytes = response.body
            if response_body_bytes:
                response_body = json.loads(response_body_bytes)
        except Exception as e:
            handle_error_with_log(e, "parsing response body", request_id)
    
    # 共通化関数でコンテキスト生成とログエントリ作成
    context = generate_full_context()
    log_entry = create_log_entry(
        level="ERROR" if response.status_code >= 400 else "INFO",
        request_id=request_id,
        user_id=user_id,
        client_ip=source_ip,
        http_method=request.method,
        api_path=request.url.path,
        status_code=response.status_code,
        response_time_ms=response_time_ms,
        note="",
        **context
    )
    
    target_size = 1000
    
    low, high = 0, 2000
    best_note_length = 0
    
    while low <= high:
        mid = (low + high) // 2
        log_entry["note"] = "A" * mid
        
        test_json = json.dumps(log_entry, separators=(',', ':'))
        test_size = len(test_json.encode('utf-8'))
        
        if test_size == target_size:
            best_note_length = mid
            break
        elif test_size < target_size:
            best_note_length = mid
            low = mid + 1
        else:
            high = mid - 1
    
    log_entry["note"] = "A" * best_note_length
    
    # Parquetにも詳細な内容を送信
    send_to_firehose(log_entry, log_entry)
    
    return response

# --- ルートエンドポイント ---
@app.get("/")
async def root():
    return {"message": "API Service is running"}

# --- ヘルスチェックエンドポイント ---
@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False
    )
