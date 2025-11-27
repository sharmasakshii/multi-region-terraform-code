"""
Worker Service - Private Background Job Processor
Handles asynchronous background jobs and task processing
"""
from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
import os
import logging
from datetime import datetime
import asyncio
from typing import Optional, Dict
import uuid

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Worker Service", version="1.0.0")

# Environment variables
REGION = os.getenv("AZURE_REGION", "unknown")
SQL_CONNECTION_STRING = os.getenv("SQL_CONNECTION_STRING", "")
STORAGE_CONNECTION_STRING = os.getenv("STORAGE_CONNECTION_STRING", "")

# Job queue and status tracking
jobs_queue: Dict[str, dict] = {}

class JobRequest(BaseModel):
    job_type: str
    payload: Optional[dict] = None
    priority: Optional[int] = 1

class JobStatus(BaseModel):
    job_id: str
    status: str
    result: Optional[dict] = None

@app.get("/")
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "worker-service",
        "region": REGION,
        "timestamp": datetime.utcnow().isoformat(),
        "active_jobs": len([j for j in jobs_queue.values() if j["status"] == "running"]),
        "version": "1.0.0"
    }

async def process_job(job_id: str, job_type: str, payload: dict):
    """Background job processing function"""
    try:
        logger.info(f"Starting job {job_id} of type {job_type} in {REGION}")
        jobs_queue[job_id]["status"] = "running"
        jobs_queue[job_id]["started_at"] = datetime.utcnow().isoformat()

        # Simulate job processing based on type
        if job_type == "data_import":
            await asyncio.sleep(2)  # Simulate import
            result = {"imported_records": payload.get("record_count", 100)}

        elif job_type == "data_export":
            await asyncio.sleep(3)  # Simulate export
            result = {"exported_file": f"export_{job_id}.csv"}

        elif job_type == "data_sync":
            await asyncio.sleep(1.5)  # Simulate sync
            result = {"synced_items": payload.get("item_count", 50)}

        elif job_type == "cleanup":
            await asyncio.sleep(1)  # Simulate cleanup
            result = {"deleted_items": payload.get("old_items", 25)}

        else:
            await asyncio.sleep(1)  # Default processing
            result = {"processed": True}

        # Mark job as completed
        jobs_queue[job_id]["status"] = "completed"
        jobs_queue[job_id]["result"] = result
        jobs_queue[job_id]["completed_at"] = datetime.utcnow().isoformat()

        logger.info(f"Completed job {job_id} in {REGION}")

    except Exception as e:
        logger.error(f"Job {job_id} failed: {str(e)}")
        jobs_queue[job_id]["status"] = "failed"
        jobs_queue[job_id]["error"] = str(e)
        jobs_queue[job_id]["failed_at"] = datetime.utcnow().isoformat()

@app.post("/job/submit")
async def submit_job(job: JobRequest, background_tasks: BackgroundTasks):
    """Submit a new background job"""
    job_id = str(uuid.uuid4())

    # Add job to queue
    jobs_queue[job_id] = {
        "job_id": job_id,
        "job_type": job.job_type,
        "payload": job.payload or {},
        "priority": job.priority,
        "status": "queued",
        "region": REGION,
        "created_at": datetime.utcnow().isoformat()
    }

    # Start processing in background
    background_tasks.add_task(process_job, job_id, job.job_type, job.payload or {})

    logger.info(f"Job {job_id} queued in {REGION}")

    return {
        "message": "Job submitted successfully",
        "job_id": job_id,
        "status": "queued",
        "region": REGION
    }

@app.get("/job/{job_id}")
async def get_job_status(job_id: str):
    """Get job status"""
    if job_id not in jobs_queue:
        return {"error": "Job not found"}, 404

    return jobs_queue[job_id]

@app.get("/jobs/active")
async def get_active_jobs():
    """Get all active jobs"""
    active = [j for j in jobs_queue.values() if j["status"] in ["queued", "running"]]
    return {
        "active_jobs": active,
        "count": len(active),
        "region": REGION
    }

@app.get("/jobs/completed")
async def get_completed_jobs():
    """Get all completed jobs"""
    completed = [j for j in jobs_queue.values() if j["status"] == "completed"]
    return {
        "completed_jobs": completed,
        "count": len(completed),
        "region": REGION
    }

@app.get("/jobs/failed")
async def get_failed_jobs():
    """Get all failed jobs"""
    failed = [j for j in jobs_queue.values() if j["status"] == "failed"]
    return {
        "failed_jobs": failed,
        "count": len(failed),
        "region": REGION
    }

@app.post("/job/retry/{job_id}")
async def retry_job(job_id: str, background_tasks: BackgroundTasks):
    """Retry a failed job"""
    if job_id not in jobs_queue:
        return {"error": "Job not found"}, 404

    job = jobs_queue[job_id]
    if job["status"] != "failed":
        return {"error": "Only failed jobs can be retried"}, 400

    # Reset job status
    job["status"] = "queued"
    job["retried_at"] = datetime.utcnow().isoformat()

    # Restart processing
    background_tasks.add_task(process_job, job_id, job["job_type"], job["payload"])

    return {
        "message": "Job retry initiated",
        "job_id": job_id,
        "region": REGION
    }

@app.get("/stats")
async def get_stats():
    """Get worker statistics"""
    return {
        "service": "worker-service",
        "region": REGION,
        "stats": {
            "total_jobs": len(jobs_queue),
            "queued": len([j for j in jobs_queue.values() if j["status"] == "queued"]),
            "running": len([j for j in jobs_queue.values() if j["status"] == "running"]),
            "completed": len([j for j in jobs_queue.values() if j["status"] == "completed"]),
            "failed": len([j for j in jobs_queue.values() if j["status"] == "failed"])
        },
        "timestamp": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=80)
