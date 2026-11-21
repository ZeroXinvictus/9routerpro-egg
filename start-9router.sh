#!/bin/bash
export PORT="${SERVER_PORT:-20128}"
export HOSTNAME="0.0.0.0"
export BASE_URL="${BASE_URL:-http://127.0.0.1:${PORT}}"
export DATA_DIR="/home/container/data"
mkdir -p "$DATA_DIR"

(
  until curl -s -o /dev/null "http://127.0.0.1:${PORT}/"; do
    sleep 1
  done
  echo "9router ready on port ${PORT}"
) &

cd /app
exec node custom-server.js
