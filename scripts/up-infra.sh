#!/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "🚀 Starting INFTA stack..."
docker compose -f docker/infta/docker-compose.infta.yml up -d
