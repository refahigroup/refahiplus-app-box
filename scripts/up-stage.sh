#!/bin/bash
set -e
cd "$(dirname "$0")/.."

VERSION="${1:-latest}"
echo "🚀 Starting STAGE stack with VERSION=${VERSION}..."
VERSION="$VERSION" docker compose -f docker/stage/docker-compose.stage.yml up -d
