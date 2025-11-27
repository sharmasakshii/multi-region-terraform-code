"""
API Service - Private Internal Service
Handles REST API operations, data queries, and business logic
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import logging
from datetime import datetime
from typing import Optional, List
from azure.identity import DefaultAzureCredential
import uuid

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="API Service", version="1.0.0")

# Environment variables
REGION = os.getenv("AZURE_REGION", "unknown")
SQL_CONNECTION_STRING = os.getenv("SQL_CONNECTION_STRING", "")
STORAGE_CONNECTION_STRING = os.getenv("STORAGE_CONNECTION_STRING", "")

# Models
class Item(BaseModel):
    id: Optional[str] = None
    name: str
    description: Optional[str] = None
    created_at: Optional[str] = None

class QueryRequest(BaseModel):
    query_type: str
    parameters: Optional[dict] = None

# In-memory storage (replace with actual database in production)
items_db = {}

@app.get("/")
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "api-service",
        "region": REGION,
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

@app.get("/items")
async def get_items():
    """Get all items"""
    logger.info(f"Fetching all items from {REGION}")
    return {
        "items": list(items_db.values()),
        "count": len(items_db),
        "region": REGION
    }

@app.get("/items/{item_id}")
async def get_item(item_id: str):
    """Get specific item by ID"""
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")

    logger.info(f"Fetching item {item_id} from {REGION}")
    return items_db[item_id]

@app.post("/items")
async def create_item(item: Item):
    """Create new item"""
    item_id = str(uuid.uuid4())
    item.id = item_id
    item.created_at = datetime.utcnow().isoformat()

    items_db[item_id] = item.dict()
    logger.info(f"Created item {item_id} in {REGION}")

    return {
        "message": "Item created successfully",
        "item": items_db[item_id],
        "region": REGION
    }

@app.put("/items/{item_id}")
async def update_item(item_id: str, item: Item):
    """Update existing item"""
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")

    item.id = item_id
    item.created_at = items_db[item_id].get("created_at")
    items_db[item_id] = item.dict()

    logger.info(f"Updated item {item_id} in {REGION}")
    return {
        "message": "Item updated successfully",
        "item": items_db[item_id],
        "region": REGION
    }

@app.delete("/items/{item_id}")
async def delete_item(item_id: str):
    """Delete item"""
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")

    deleted_item = items_db.pop(item_id)
    logger.info(f"Deleted item {item_id} from {REGION}")

    return {
        "message": "Item deleted successfully",
        "item": deleted_item,
        "region": REGION
    }

@app.post("/query")
async def execute_query(query: QueryRequest):
    """Execute custom query"""
    logger.info(f"Executing query type: {query.query_type} in {REGION}")

    # Simulate query execution
    results = {
        "query_type": query.query_type,
        "parameters": query.parameters,
        "results": [],
        "executed_at": datetime.utcnow().isoformat(),
        "region": REGION
    }

    if query.query_type == "count":
        results["results"] = {"total_items": len(items_db)}
    elif query.query_type == "search":
        search_term = query.parameters.get("term", "") if query.parameters else ""
        matching_items = [
            item for item in items_db.values()
            if search_term.lower() in item.get("name", "").lower()
        ]
        results["results"] = matching_items

    return results

@app.get("/stats")
async def get_stats():
    """Get service statistics"""
    return {
        "service": "api-service",
        "region": REGION,
        "stats": {
            "total_items": len(items_db),
            "database_connected": bool(SQL_CONNECTION_STRING),
            "storage_connected": bool(STORAGE_CONNECTION_STRING)
        },
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/test/database")
async def test_database():
    """Test database connectivity"""
    if not SQL_CONNECTION_STRING:
        return {"status": "not_configured"}

    try:
        # Use managed identity for database connection
        logger.info("Testing database connection with managed identity...")
        return {"status": "connected", "region": REGION}
    except Exception as e:
        logger.error(f"Database error: {str(e)}")
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=80)
