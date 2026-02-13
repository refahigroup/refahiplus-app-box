#!/bin/bash
set -euo pipefail

ENV="$1" 
SERVICE="$2"

BASE="/opt/refahi-infra"
DATA_BASE="/opt/refahi-data"

ENV_FILE="${DATA_BASE}/.env"
TOKEN_FILE="${DATA_BASE}/github.p"
COMPOSE_FILE="${BASE}/docker/${ENV}/${SERVICE}.yml"

echo "🚀 Deploying ENV=$ENV SERVICE=$SERVICE"
echo "📂 Using compose file: $COMPOSE_FILE"

if [ -f "$TOKEN_FILE" ]; then
  cat "$TOKEN_FILE" | docker login registry.refahi.xyz -u saeed --password-stdin
else
  echo "WARNING: GitHub token file not found at $TOKEN_FILE"
fi

# Pull latest images for this env
echo "📥 docker compose pull..."
docker compose -f "$COMPOSE_FILE" pull

# Apply new configuration and containers
echo "📦 docker compose up -d --remove-orphans..."
if [ -f "$ENV_FILE" ]; then
  env -i docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --remove-orphans
else
  docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
fi

echo "✅ Deploy complete for ENV=$ENV SERVICE=$SERVICE"
