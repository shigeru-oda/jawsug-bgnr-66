import json
import logging
import os
import random
import time
import uuid
import requests
from datetime import datetime
from typing import Dict, Any, Optional, List

import boto3
import uvicorn
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from pythonjsonlogger import jsonlogger

app = FastAPI(title="API Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
            metadata_log = {
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "level": "WARNING",
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

logger = logging.getLogger("api_logger")
logger.setLevel(logging.INFO)

console_handler = logging.StreamHandler()
logger.addHandler(console_handler)

class OrderRequest(BaseModel):
    item_id: str

class OrderResponse(BaseModel):
    order_id: str
    
class BatchRequest(BaseModel):
    count: int

class BatchResponse(BaseModel):
    results: List[OrderResponse]

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
            error_log = {
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "level": "ERROR",
                "message": f"Error parsing request body: {str(e)}"
            }
            print(json.dumps(error_log))
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
            error_log = {
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "level": "ERROR",
                "message": f"Error parsing response body: {str(e)}"
            }
            print(json.dumps(error_log))
    
    random_values = generate_random_values()
    random_order = generate_random_order_data()
    
    log_entry = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "level": "ERROR" if response.status_code >= 400 else "INFO",
        "request_id": request_id,
        "user_id": user_id,
        "client_ip": source_ip,
        "http_method": request.method,
        "api_path": request.url.path,
        "status_code": response.status_code,
        "response_time_ms": response_time_ms,
        "request_body": random_order,
        "auth_method": random_values["auth_method"],
        "user_agent": random_values["user_agent"],
        "note": "",
        "environment": random_values["environment"],
        "region": random_values["region"]
    }
    
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
    
    print(json.dumps(log_entry))
    
    try:
        firehose_log = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": "INFO",
            "message": f"Sending log for path: {request.url.path} to Firehose"
        }
        print(json.dumps(firehose_log))
        
        firehose_client = boto3.client('firehose', region_name=os.environ.get('AWS_REGION', 'ap-northeast-1'))
        
        parquet_stream = os.environ.get('FIREHOSE_STREAM_PARQUET')
        if parquet_stream:
            firehose_client.put_record(
                DeliveryStreamName=parquet_stream,
                Record={'Data': json.dumps(log_entry) + '\n'}
            )
        
        iceberg_stream = os.environ.get('FIREHOSE_STREAM_ICEBERG')
        if iceberg_stream:
            firehose_client.put_record(
                DeliveryStreamName=iceberg_stream,
                Record={'Data': json.dumps(log_entry) + '\n'}
            )
            
        json_stream = os.environ.get('FIREHOSE_STREAM_JSON')
        if json_stream:
            firehose_client.put_record(
                DeliveryStreamName=json_stream,
                Record={'Data': json.dumps(log_entry) + '\n'}
            )
    except Exception as e:
        error_log = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": "ERROR",
            "message": f"Error sending to Firehose: {str(e)}"
        }
        print(json.dumps(error_log))
    
    return response

@app.get("/")
async def root():
    return {"message": "API Service is running"}

@app.post("/api/v1/orders", response_model=OrderResponse, status_code=201)
async def create_order(order: OrderRequest, response: Response):
    response.headers["X-Status-Message"] = "Created"
    
    order_id = str(uuid.uuid4())[:5]
    
    return {"order_id": order_id}

@app.post("/api/v1/batch", response_model=BatchResponse, status_code=201)
async def create_batch_orders(batch: BatchRequest, response: Response):
    response.headers["X-Status-Message"] = "Created"
    
    results = []
    
    for _ in range(batch.count):
        random_user_id = str(uuid.uuid4())
        
        random_item_id = f"item-{str(uuid.uuid4())[:8]}"
        
        batch_log = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": "INFO",
            "message": f"Processing batch order with X-User-ID: {random_user_id}, item_id: {random_item_id}"
        }
        print(json.dumps(batch_log))
        
        order_request = OrderRequest(item_id=random_item_id)
        order_id = str(uuid.uuid4())[:5]  # 既存の実装と同様に注文IDを生成
        
        results.append(OrderResponse(order_id=order_id))
    
    return {"results": results}

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
