#!/bin/bash
set -e

BASE="/opt/refahi-data"

echo "📁 Creating persistent data directories under $BASE"

DIRS=(
  "$BASE/postgres"
  "$BASE/postgres/data"
  "$BASE/postgres/backups"
  "$BASE/redis"
  "$BASE/rabbitmq"
  "$BASE/elasticsearch"
  "$BASE/certbot/conf"
  "$BASE/certbot/www"
  "$BASE/nginx/logs"
  "$BASE/backups/postgres"
)

for d in "${DIRS[@]}"; do
  echo "📂 Ensuring directory exists: $d"
  mkdir -p "$d"
done

echo "🔧 Setting permissions..."

# Allow docker containers to read/write properly
chmod -R 755 "$BASE"

# Specifically for certbot (Let’s Encrypt keys)
chmod -R 700 "$BASE/certbot/conf"

echo "✅ Data directories initialized successfully."
