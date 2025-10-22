#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(dirname "$0")")" || exit 1
echo "Running quick diagnostics..."

echo
echo "1) Python syntax / pyflakes (backend)"
python -m pyflakes backend || true

echo
echo "2) flake8 (installing if missing)"
python -m pip install --quiet flake8 || true
flake8 backend || true

echo
echo "3) Show Node/JS lint (dashboard) if package.json exists"
if [ -f dashboard/package.json ]; then
  echo "Running npm install --silent (only if needed) and lint"
  (cd dashboard && npm install --silent) || true
  (cd dashboard && npm run lint --silent) || true
else
  echo "No dashboard/package.json found - skipping JS lint"
fi

echo
echo "4) List recent modified files (top 50)"
find . -type f -printf '%T@ %p\n' | sort -n | tail -n 50

echo
echo "5) Docker compose status (if present)"
if [ -f docker-compose.dev.yml ]; then
  docker compose -f docker-compose.dev.yml ps || true
else
  echo "No docker-compose.dev.yml found"
fi

echo
echo "Diagnostics complete. Paste pyflakes/flake8 output here and I will provide exact fixes."

# ensure files saved
chmod +x backend/worker.py
chmod +x dev/fix_problems.sh

# run diagnostics
./dev/fix_problems.sh

# start Redis (if you want background jobs)
docker run -d --name ai-redis -p 6379:6379 redis:7 || true

# start backend in one terminal
python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000

# start worker in another terminal
export REDIS_URL=redis://localhost:6379
python backend/worker.py

# run smoke tests (in a separate terminal)
chmod +x tests/smoke_tests.sh || true
./tests/smoke_tests.sh

docker compose -f docker-compose.dev.yml logs --no-color backend > /tmp/backend.logs.txt
cat /tmp/backend.logs.txt