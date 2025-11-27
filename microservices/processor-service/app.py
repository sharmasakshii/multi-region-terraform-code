"""
Processor Service - Private Data Processing Service
Handles compute-intensive data processing tasks
"""
from fastapi import FastAPI
from pydantic import BaseModel
import os
import logging
from datetime import datetime
from typing import Optional, List
import json
import hashlib

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Processor Service", version="1.0.0")

# Environment variables
REGION = os.getenv("AZURE_REGION", "unknown")
SQL_CONNECTION_STRING = os.getenv("SQL_CONNECTION_STRING", "")
STORAGE_CONNECTION_STRING = os.getenv("STORAGE_CONNECTION_STRING", "")

class ProcessRequest(BaseModel):
    data: List[dict]
    operation: str
    options: Optional[dict] = None

class TransformRequest(BaseModel):
    input_data: str
    transform_type: str

@app.get("/")
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "processor-service",
        "region": REGION,
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

@app.post("/process/aggregate")
async def process_aggregate(request: ProcessRequest):
    """Aggregate data processing"""
    logger.info(f"Processing aggregation in {REGION}")

    try:
        data = request.data
        operation = request.operation

        if operation == "sum":
            result = sum(item.get("value", 0) for item in data)
        elif operation == "average":
            values = [item.get("value", 0) for item in data]
            result = sum(values) / len(values) if values else 0
        elif operation == "count":
            result = len(data)
        elif operation == "max":
            result = max(item.get("value", 0) for item in data) if data else 0
        elif operation == "min":
            result = min(item.get("value", 0) for item in data) if data else 0
        else:
            result = None

        return {
            "operation": operation,
            "result": result,
            "processed_items": len(data),
            "region": REGION,
            "timestamp": datetime.utcnow().isoformat()
        }

    except Exception as e:
        logger.error(f"Aggregation error: {str(e)}")
        return {"error": str(e)}, 500

@app.post("/process/transform")
async def process_transform(request: TransformRequest):
    """Transform data"""
    logger.info(f"Processing transformation in {REGION}")

    try:
        input_data = request.input_data
        transform_type = request.transform_type

        if transform_type == "uppercase":
            result = input_data.upper()
        elif transform_type == "lowercase":
            result = input_data.lower()
        elif transform_type == "hash":
            result = hashlib.sha256(input_data.encode()).hexdigest()
        elif transform_type == "reverse":
            result = input_data[::-1]
        elif transform_type == "length":
            result = len(input_data)
        else:
            result = input_data

        return {
            "transform_type": transform_type,
            "input": input_data[:100],  # Truncate for response
            "result": result,
            "region": REGION,
            "timestamp": datetime.utcnow().isoformat()
        }

    except Exception as e:
        logger.error(f"Transform error: {str(e)}")
        return {"error": str(e)}, 500

@app.post("/process/analyze")
async def process_analyze(request: ProcessRequest):
    """Analyze data"""
    logger.info(f"Processing analysis in {REGION}")

    try:
        data = request.data

        analysis = {
            "total_items": len(data),
            "unique_keys": len(set(str(item.keys()) for item in data)),
            "has_values": sum(1 for item in data if item.get("value") is not None),
            "data_types": {}
        }

        # Analyze data types
        for item in data:
            for key, value in item.items():
                type_name = type(value).__name__
                if key not in analysis["data_types"]:
                    analysis["data_types"][key] = {}
                analysis["data_types"][key][type_name] = \
                    analysis["data_types"][key].get(type_name, 0) + 1

        return {
            "analysis": analysis,
            "region": REGION,
            "timestamp": datetime.utcnow().isoformat()
        }

    except Exception as e:
        logger.error(f"Analysis error: {str(e)}")
        return {"error": str(e)}, 500

@app.post("/process/filter")
async def process_filter(request: ProcessRequest):
    """Filter data based on conditions"""
    logger.info(f"Processing filtering in {REGION}")

    try:
        data = request.data
        options = request.options or {}
        filter_key = options.get("key", "value")
        filter_condition = options.get("condition", "greater_than")
        filter_value = options.get("value", 0)

        filtered_data = []
        for item in data:
            item_value = item.get(filter_key)

            if filter_condition == "greater_than" and item_value > filter_value:
                filtered_data.append(item)
            elif filter_condition == "less_than" and item_value < filter_value:
                filtered_data.append(item)
            elif filter_condition == "equals" and item_value == filter_value:
                filtered_data.append(item)
            elif filter_condition == "not_equals" and item_value != filter_value:
                filtered_data.append(item)

        return {
            "original_count": len(data),
            "filtered_count": len(filtered_data),
            "filtered_data": filtered_data,
            "filter_condition": filter_condition,
            "region": REGION,
            "timestamp": datetime.utcnow().isoformat()
        }

    except Exception as e:
        logger.error(f"Filtering error: {str(e)}")
        return {"error": str(e)}, 500

@app.post("/process/batch")
async def process_batch(request: ProcessRequest):
    """Batch process multiple operations"""
    logger.info(f"Processing batch in {REGION}")

    try:
        data = request.data
        operations = request.options.get("operations", []) if request.options else []

        results = []
        for operation in operations:
            # Process each operation
            op_result = {
                "operation": operation,
                "processed": True,
                "timestamp": datetime.utcnow().isoformat()
            }
            results.append(op_result)

        return {
            "batch_results": results,
            "total_operations": len(operations),
            "data_items": len(data),
            "region": REGION,
            "timestamp": datetime.utcnow().isoformat()
        }

    except Exception as e:
        logger.error(f"Batch processing error: {str(e)}")
        return {"error": str(e)}, 500

@app.get("/stats")
async def get_stats():
    """Get processor statistics"""
    return {
        "service": "processor-service",
        "region": REGION,
        "capabilities": [
            "aggregate",
            "transform",
            "analyze",
            "filter",
            "batch"
        ],
        "timestamp": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=80)
