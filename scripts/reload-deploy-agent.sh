#!/bin/bash
set -euo pipefail

SERVICE_NAME="refahi-deploy-agent"
BASE="/opt/refahi-infra"
AGENT_DIR="$BASE/deploy-agent"
DEPLOY_SCRIPT="$AGENT_DIR/deploy.sh"

echo "==============================================="
echo "🔁 Reloading Refahi Deploy Agent"
echo "==============================================="

# -----------------------------------------
# Ensure deploy.sh is executable
# -----------------------------------------
if [ -f "$DEPLOY_SCRIPT" ]; then
  echo "🔧 Ensuring deploy.sh is executable..."
  chmod +x "$DEPLOY_SCRIPT"
else
  echo "❌ ERROR: deploy.sh not found at $DEPLOY_SCRIPT"
  exit 1
fi

# -----------------------------------------
# Systemd reload + service restart
# -----------------------------------------
echo "🔁 Reloading systemd daemon..."
systemctl daemon-reload

echo "🚀 Restarting systemd service: $SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

echo "==============================================="
echo "✅ Deploy Agent reloaded successfully."
echo "==============================================="

systemctl status "$SERVICE_NAME" --no-pager -l | sed -n '1,10p'
