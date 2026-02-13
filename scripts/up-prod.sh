#!/bin/bash
set -e
cd "$(dirname "$0")/.."

VERSION="${1:-latest}"
echo "🚀 Starting PROD stack with VERSION=${VERSION}..."
VERSION="$VERSION" docker compose -f docker/prod/docker-compose.prod.yml up -d
