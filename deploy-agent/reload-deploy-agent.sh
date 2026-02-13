#!/bin/bash
set -euo pipefail

SERVICE_NAME="refahi-deploy-agent"
BASE="/opt/refahi-infra"

echo "🔁 Reloading Deploy Agent..."

if [ -f "$BASE/deploy-agent/deploy.sh" ]; then
  echo "🔧 Ensuring deploy.sh is executable..."
  chmod +x "$BASE/deploy-agent/deploy.sh"
else
  echo "❌ deploy.sh not found at $BASE/deploy-agent/deploy.sh"
  exit 1
fi

echo "🔁 Reloading systemd daemon..."
systemctl daemon-reload

echo "🚀 Restarting service: $SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

echo "✅ Deploy Agent reloaded successfully."
systemctl status "$SERVICE_NAME" --no-pager -l | sed -n '1,10p'
