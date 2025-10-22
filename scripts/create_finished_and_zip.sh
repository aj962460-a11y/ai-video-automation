echo "Done. New zip: /workspaces/ai-video-automation/${NEW_ZIP}"

# ---- changed code: do NOT run interactive commands from this script ----
cat <<'INSTRUCTIONS'

Files generated and zipped at: /workspaces/ai-video-automation/${NEW_ZIP}

Next steps (run manually in your devcontainer terminal):

1) Copy env and edit (do this manually; do NOT run an editor from a non-interactive script)
   cp .env.example .env
   # open and set AI_PROVIDER=pika and any other values:
   # $EDITOR .env

2) Start local services
   docker compose -f docker-compose.dev.yml up --build -d

3) Install python deps
   python -m pip install -r backend/requirements.txt

4) (Optional) Run migrations (ensure backend/alembic exists)
   cd backend
   alembic -c alembic.ini upgrade head
   cd ..

5) Start backend (run from repo root)
   python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000

6) Run smoke tests (in a separate terminal)
   curl -s http://localhost:8000/ | jq .
   curl -s -X POST http://localhost:8000/api/generate -H "Content-Type: application/json" -d '{"prompt":"test video"}' | jq .
   curl -s http://localhost:8000/api/job/1 | jq .
   curl -s http://localhost:8000/api/auth/start/youtube | jq .
   curl -s "http://localhost:8000/api/auth/callback/youtube?code=testcode" | jq .
   curl -s -X POST http://localhost:8000/api/post -H "Content-Type: application/json" -d '{"provider":"youtube","media_url":"https://example.com/video.mp4","caption":"hi"}' | jq .
   curl -s "http://localhost:8000/api/monetization/full?provider=youtube" | jq .

If any command fails, collect backend logs:
   docker compose -f docker-compose.dev.yml logs --no-color backend > /tmp/backend.logs.txt
   cat /tmp/backend.logs.txt

INSTRUCTIONS