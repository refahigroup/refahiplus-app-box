#!/bin/bash
set -euo pipefail

REPO_DIR="/opt/refahi-infra"
RELOAD_SCRIPT="$REPO_DIR/scripts/reload-deploy-agent.sh"

echo "=============================================="
echo "🔄 Refahi Infra Safe Pull + Auto-Reload"
echo "=============================================="

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "❌ ERROR: Directory $REPO_DIR is not a git repository."
  exit 1
fi

echo "📁 Changing directory → $REPO_DIR"
cd "$REPO_DIR"

echo "🧹 Cleaning uncommitted changes (git reset --hard)..."
git reset --hard

echo "📥 Pulling latest changes from remote origin..."
git pull --rebase --autostash

echo "🔧 Ensuring reload script is executable..."
chmod +x "$RELOAD_SCRIPT"

echo "🚀 Running reload-deploy-agent.sh..."
bash "$RELOAD_SCRIPT"

echo "=============================================="
echo "✅ Infra updated and Deploy Agent reloaded."
echo "=============================================="
