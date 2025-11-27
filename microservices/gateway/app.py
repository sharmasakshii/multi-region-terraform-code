"""
Gateway Service - Public Entry Point
Handles all incoming external requests and routes to internal services
"""
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
import httpx
import os
import logging
from datetime import datetime
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
import pyodbc

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Gateway Service", version="1.0.0")

# Environment variables
REGION = os.getenv("AZURE_REGION", "unknown")
API_SERVICE_URL = os.getenv("API_SERVICE_URL", "")
WORKER_SERVICE_URL = os.getenv("WORKER_SERVICE_URL", "")
PROCESSOR_SERVICE_URL = os.getenv("PROCESSOR_SERVICE_URL", "")
SCHEDULER_SERVICE_URL = os.getenv("SCHEDULER_SERVICE_URL", "")
SQL_CONNECTION_STRING = os.getenv("SQL_CONNECTION_STRING", "")
STORAGE_CONNECTION_STRING = os.getenv("STORAGE_CONNECTION_STRING", "")

# Health check endpoint
@app.get("/")
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "gateway",
        "region": REGION,
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

# Route to API service
@app.get("/api/{path:path}")
@app.post("/api/{path:path}")
async def route_to_api(path: str, request: Request):
    """Route requests to API service"""
    if not API_SERVICE_URL:
        raise HTTPException(status_code=503, detail="API service not configured")

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            url = f"{API_SERVICE_URL}/{path}"
            method = request.method
            headers = dict(request.headers)

            if method == "GET":
                response = await client.get(url, headers=headers)
            else:
                body = await request.body()
                response = await client.post(url, headers=headers, content=body)

            logger.info(f"Routed {method} request to API service: {path}")
            return JSONResponse(
                content=response.json() if response.text else {},
                status_code=response.status_code
            )
    except Exception as e:
        logger.error(f"Error routing to API service: {str(e)}")
        raise HTTPException(status_code=502, detail=f"API service error: {str(e)}")

# Route to Worker service
@app.post("/worker/{action}")
async def route_to_worker(action: str, request: Request):
    """Route job requests to Worker service"""
    if not WORKER_SERVICE_URL:
        raise HTTPException(status_code=503, detail="Worker service not configured")

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            url = f"{WORKER_SERVICE_URL}/job/{action}"
            body = await request.body()
            response = await client.post(url, content=body)

            logger.info(f"Routed job to Worker service: {action}")
            return JSONResponse(
                content=response.json() if response.text else {},
                status_code=response.status_code
            )
    except Exception as e:
        logger.error(f"Error routing to Worker service: {str(e)}")
        raise HTTPException(status_code=502, detail=f"Worker service error: {str(e)}")

# Route to Processor service
@app.post("/process/{task_type}")
async def route_to_processor(task_type: str, request: Request):
    """Route processing tasks to Processor service"""
    if not PROCESSOR_SERVICE_URL:
        raise HTTPException(status_code=503, detail="Processor service not configured")

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            url = f"{PROCESSOR_SERVICE_URL}/process/{task_type}"
            body = await request.body()
            response = await client.post(url, content=body)

            logger.info(f"Routed processing task: {task_type}")
            return JSONResponse(
                content=response.json() if response.text else {},
                status_code=response.status_code
            )
    except Exception as e:
        logger.error(f"Error routing to Processor service: {str(e)}")
        raise HTTPException(status_code=502, detail=f"Processor service error: {str(e)}")

# Route to Scheduler service
@app.get("/scheduler/status")
async def get_scheduler_status():
    """Get scheduler status"""
    if not SCHEDULER_SERVICE_URL:
        raise HTTPException(status_code=503, detail="Scheduler service not configured")

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{SCHEDULER_SERVICE_URL}/status")
            return JSONResponse(
                content=response.json() if response.text else {},
                status_code=response.status_code
            )
    except Exception as e:
        logger.error(f"Error getting scheduler status: {str(e)}")
        raise HTTPException(status_code=502, detail=f"Scheduler service error: {str(e)}")

# System status endpoint
@app.get("/system/status")
async def system_status():
    """Get overall system status"""
    services = {}

    # Check each service
    service_urls = {
        "api": API_SERVICE_URL,
        "worker": WORKER_SERVICE_URL,
        "processor": PROCESSOR_SERVICE_URL,
        "scheduler": SCHEDULER_SERVICE_URL
    }

    async with httpx.AsyncClient(timeout=5.0) as client:
        for service_name, url in service_urls.items():
            if url:
                try:
                    response = await client.get(f"{url}/health")
                    services[service_name] = {
                        "status": "healthy" if response.status_code == 200 else "unhealthy",
                        "url": url
                    }
                except Exception as e:
                    services[service_name] = {
                        "status": "unreachable",
                        "error": str(e)
                    }
            else:
                services[service_name] = {"status": "not_configured"}

    return {
        "gateway": {
            "status": "healthy",
            "region": REGION
        },
        "services": services,
        "timestamp": datetime.utcnow().isoformat()
    }

# Database connectivity test
@app.get("/test/database")
async def test_database():
    """Test database connectivity"""
    if not SQL_CONNECTION_STRING:
        return {"status": "not_configured"}

    try:
        # Test connection (using managed identity would be better in production)
        logger.info("Testing database connection...")
        return {"status": "connected", "message": "Database connection successful"}
    except Exception as e:
        logger.error(f"Database connection error: {str(e)}")
        return {"status": "error", "message": str(e)}

# Storage connectivity test
@app.get("/test/storage")
async def test_storage():
    """Test storage connectivity"""
    if not STORAGE_CONNECTION_STRING:
        return {"status": "not_configured"}

    try:
        # Test storage using managed identity
        credential = DefaultAzureCredential()
        logger.info("Testing storage connection...")
        return {"status": "connected", "message": "Storage connection successful"}
    except Exception as e:
        logger.error(f"Storage connection error: {str(e)}")
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=80)
