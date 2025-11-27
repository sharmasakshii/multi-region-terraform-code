"""
Scheduler Service - Private Task Scheduling Service
Manages scheduled tasks and cron jobs
"""
from fastapi import FastAPI
from pydantic import BaseModel
import os
import logging
from datetime import datetime, timedelta
from typing import Optional, List
import uuid
from apscheduler.schedulers.background import BackgroundScheduler

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Scheduler Service", version="1.0.0")

# Environment variables
REGION = os.getenv("AZURE_REGION", "unknown")
SQL_CONNECTION_STRING = os.getenv("SQL_CONNECTION_STRING", "")
STORAGE_CONNECTION_STRING = os.getenv("STORAGE_CONNECTION_STRING", "")

# Scheduler instance
scheduler = BackgroundScheduler()
scheduled_tasks = {}

class ScheduleTask(BaseModel):
    name: str
    schedule_type: str  # cron, interval, date
    schedule_value: str
    task_type: str
    payload: Optional[dict] = None
    enabled: Optional[bool] = True

class TaskExecution(BaseModel):
    task_id: str
    status: str
    result: Optional[dict] = None

# Task execution history
execution_history = []

def execute_scheduled_task(task_id: str, task_name: str, task_type: str, payload: dict):
    """Execute a scheduled task"""
    try:
        logger.info(f"Executing scheduled task {task_id}: {task_name} in {REGION}")

        execution = {
            "task_id": task_id,
            "task_name": task_name,
            "task_type": task_type,
            "payload": payload,
            "status": "completed",
            "executed_at": datetime.utcnow().isoformat(),
            "region": REGION
        }

        # Simulate task execution based on type
        if task_type == "cleanup":
            execution["result"] = {"cleaned_items": 50}
        elif task_type == "backup":
            execution["result"] = {"backup_file": f"backup_{datetime.utcnow().strftime('%Y%m%d')}.zip"}
        elif task_type == "sync":
            execution["result"] = {"synced_records": 100}
        elif task_type == "report":
            execution["result"] = {"report_generated": True}
        else:
            execution["result"] = {"executed": True}

        execution_history.append(execution)
        logger.info(f"Task {task_id} completed successfully")

    except Exception as e:
        logger.error(f"Task {task_id} failed: {str(e)}")
        execution = {
            "task_id": task_id,
            "task_name": task_name,
            "status": "failed",
            "error": str(e),
            "executed_at": datetime.utcnow().isoformat(),
            "region": REGION
        }
        execution_history.append(execution)

@app.on_event("startup")
async def startup_event():
    """Start the scheduler on app startup"""
    scheduler.start()
    logger.info(f"Scheduler started in {REGION}")

@app.on_event("shutdown")
async def shutdown_event():
    """Shutdown the scheduler gracefully"""
    scheduler.shutdown()
    logger.info(f"Scheduler stopped in {REGION}")

@app.get("/")
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "scheduler-service",
        "region": REGION,
        "scheduler_running": scheduler.running,
        "scheduled_tasks": len(scheduled_tasks),
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

@app.post("/schedule/create")
async def create_schedule(task: ScheduleTask):
    """Create a new scheduled task"""
    task_id = str(uuid.uuid4())

    try:
        # Create schedule based on type
        if task.schedule_type == "interval":
            # Parse interval (e.g., "30s", "5m", "1h")
            value = task.schedule_value
            if value.endswith("s"):
                seconds = int(value[:-1])
                scheduler.add_job(
                    execute_scheduled_task,
                    'interval',
                    seconds=seconds,
                    args=[task_id, task.name, task.task_type, task.payload or {}],
                    id=task_id
                )
            elif value.endswith("m"):
                minutes = int(value[:-1])
                scheduler.add_job(
                    execute_scheduled_task,
                    'interval',
                    minutes=minutes,
                    args=[task_id, task.name, task.task_type, task.payload or {}],
                    id=task_id
                )
            elif value.endswith("h"):
                hours = int(value[:-1])
                scheduler.add_job(
                    execute_scheduled_task,
                    'interval',
                    hours=hours,
                    args=[task_id, task.name, task.task_type, task.payload or {}],
                    id=task_id
                )

        elif task.schedule_type == "cron":
            # Cron expression (simplified - only daily at specific time)
            hour, minute = map(int, task.schedule_value.split(":"))
            scheduler.add_job(
                execute_scheduled_task,
                'cron',
                hour=hour,
                minute=minute,
                args=[task_id, task.name, task.task_type, task.payload or {}],
                id=task_id
            )

        # Store task metadata
        scheduled_tasks[task_id] = {
            "task_id": task_id,
            "name": task.name,
            "schedule_type": task.schedule_type,
            "schedule_value": task.schedule_value,
            "task_type": task.task_type,
            "payload": task.payload,
            "enabled": task.enabled,
            "created_at": datetime.utcnow().isoformat(),
            "region": REGION
        }

        logger.info(f"Created scheduled task {task_id}: {task.name}")

        return {
            "message": "Scheduled task created successfully",
            "task_id": task_id,
            "task": scheduled_tasks[task_id]
        }

    except Exception as e:
        logger.error(f"Failed to create schedule: {str(e)}")
        return {"error": str(e)}, 500

@app.get("/schedule/list")
async def list_schedules():
    """List all scheduled tasks"""
    return {
        "scheduled_tasks": list(scheduled_tasks.values()),
        "count": len(scheduled_tasks),
        "region": REGION
    }

@app.get("/schedule/{task_id}")
async def get_schedule(task_id: str):
    """Get specific scheduled task"""
    if task_id not in scheduled_tasks:
        return {"error": "Task not found"}, 404

    return scheduled_tasks[task_id]

@app.delete("/schedule/{task_id}")
async def delete_schedule(task_id: str):
    """Delete a scheduled task"""
    if task_id not in scheduled_tasks:
        return {"error": "Task not found"}, 404

    try:
        scheduler.remove_job(task_id)
        deleted_task = scheduled_tasks.pop(task_id)
        logger.info(f"Deleted scheduled task {task_id}")

        return {
            "message": "Scheduled task deleted successfully",
            "task": deleted_task
        }

    except Exception as e:
        logger.error(f"Failed to delete schedule: {str(e)}")
        return {"error": str(e)}, 500

@app.post("/schedule/{task_id}/pause")
async def pause_schedule(task_id: str):
    """Pause a scheduled task"""
    if task_id not in scheduled_tasks:
        return {"error": "Task not found"}, 404

    try:
        scheduler.pause_job(task_id)
        scheduled_tasks[task_id]["enabled"] = False
        logger.info(f"Paused scheduled task {task_id}")

        return {
            "message": "Scheduled task paused",
            "task_id": task_id
        }

    except Exception as e:
        logger.error(f"Failed to pause schedule: {str(e)}")
        return {"error": str(e)}, 500

@app.post("/schedule/{task_id}/resume")
async def resume_schedule(task_id: str):
    """Resume a paused scheduled task"""
    if task_id not in scheduled_tasks:
        return {"error": "Task not found"}, 404

    try:
        scheduler.resume_job(task_id)
        scheduled_tasks[task_id]["enabled"] = True
        logger.info(f"Resumed scheduled task {task_id}")

        return {
            "message": "Scheduled task resumed",
            "task_id": task_id
        }

    except Exception as e:
        logger.error(f"Failed to resume schedule: {str(e)}")
        return {"error": str(e)}, 500

@app.get("/executions/history")
async def get_execution_history():
    """Get task execution history"""
    return {
        "executions": execution_history[-100:],  # Last 100 executions
        "total": len(execution_history),
        "region": REGION
    }

@app.get("/status")
async def get_status():
    """Get scheduler status"""
    return {
        "scheduler_running": scheduler.running,
        "scheduled_tasks": len(scheduled_tasks),
        "total_executions": len(execution_history),
        "recent_executions": execution_history[-10:],
        "region": REGION,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/stats")
async def get_stats():
    """Get scheduler statistics"""
    completed = len([e for e in execution_history if e["status"] == "completed"])
    failed = len([e for e in execution_history if e["status"] == "failed"])

    return {
        "service": "scheduler-service",
        "region": REGION,
        "stats": {
            "scheduled_tasks": len(scheduled_tasks),
            "total_executions": len(execution_history),
            "completed_executions": completed,
            "failed_executions": failed
        },
        "timestamp": datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=80)
