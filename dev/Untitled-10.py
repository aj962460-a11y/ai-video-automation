#!/usr/bin/env python3
"""
Redis/RQ worker for the "ai-jobs" queue.

Usage:
  # start Redis (one terminal)
  docker run -d --name ai-redis -p 6379:6379 redis:7 || true

  # start worker (another terminal)
  export REDIS_URL=redis://localhost:6379
  chmod +x backend/worker.py
  python backend/worker.py
"""
import os
from rq import Worker, Queue, Connection
import redis

listen = ["ai-jobs"]
redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
conn = redis.from_url(redis_url)

if __name__ == "__main__":
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    os.chdir(repo_root)
    os.system("cd /workspaces/ai-video-automation && docker compose -f docker-compose.dev.yml up -d")
    os.system("cd /workspaces/ai-video-automation && python -m pip install -r backend/requirements.txt")
    os.system("ls -la dashboard/public/manifest.json dashboard/public/service-worker.js dashboard/public/icons || true")
    os.system("python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000")
    os.system("cd dashboard && npm install")
    os.system("cd dashboard && npm start")
    with Connection(conn):
        worker = Worker(list(map(Queue, listen)))
        worker.work()