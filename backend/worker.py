#!/usr/bin/env python3
"""
Run a Redis/RQ worker that listens on queue "ai-jobs".
Start with:
  export REDIS_URL=redis://localhost:6379
  python backend/worker.py
"""
import os
from rq import Worker, Queue, Connection
import redis

listen = ["ai-jobs"]
redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")

conn = redis.from_url(redis_url)

if __name__ == "__main__":
    # Change to the project directory and copy the example environment file
    os.chdir("/workspaces/ai-video-automation")
    os.system("cp .env.example .env")
    
    # Open the environment file for editing
    editor = os.getenv("EDITOR", "nano")
    os.system(f"{editor} .env")
    
    # Start the services in detached mode
    os.system("docker compose -f docker-compose.dev.yml up --build -d")
    
    # Install the required Python packages
    os.system("python -m pip install -r backend/requirements.txt")
    
    # Run database migrations
    os.system("cd backend && alembic -c alembic.ini upgrade head || true")
    
    # Start Redis in a detached Docker container
    os.system("docker run -d --name ai-redis -p 6379:6379 redis:7")
    
    # Start the application using uvicorn
    os.system("python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000")
    
    # Show logs from the backend service
    os.system("docker compose -f docker-compose.dev.yml logs --no-color backend > /tmp/backend.logs.txt")
    os.system("cat /tmp/backend.logs.txt")
    
    # List database tables
    os.system("docker compose -f docker-compose.dev.yml exec db psql -U postgres -d ai_video -c '\dt' || true")
    
    with Connection(conn):
        worker = Worker(map(Queue, listen))
        worker.work()
