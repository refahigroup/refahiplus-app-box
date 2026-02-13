#!/bin/bash
set -euo pipefail

DATA_BASE="/opt/refahi-data/certbot"
WEBROOT="${DATA_BASE}/www"
CONF_DIR="${DATA_BASE}/conf"

NGINX_CONTAINER="infra_nginx"

# Timeout ها (قابل تنظیم)
CERTBOT_TIMEOUT_SECONDS=900   # 15 دقیقه حداکثر برای renew
NGINX_RELOAD_TIMEOUT_SECONDS=30

# Lock file برای جلوگیری از اجرای هم‌زمان
LOCK_FILE="/tmp/refahi-certbot-renew.lock"

# -----------------------------
# Lock handling
# -----------------------------
if [ -e "$LOCK_FILE" ]; then
  echo "⚠️ Lock file exists: $LOCK_FILE"
  echo "Another renew process may be running. Exiting."
  exit 0
fi

trap 'rm -f "$LOCK_FILE"' EXIT
touch "$LOCK_FILE"

echo "🔁 Starting SSL renew process..."

# -----------------------------
# Ensure dirs exist
# -----------------------------
mkdir -p "$WEBROOT" "$CONF_DIR"

# -----------------------------
# Run certbot renew with timeout
# -----------------------------
echo "🔐 Running certbot renew with timeout=${CERTBOT_TIMEOUT_SECONDS}s..."

if ! timeout "${CERTBOT_TIMEOUT_SECONDS}" docker run --rm \
  -v "${WEBROOT}:/var/www/certbot" \
  -v "${CONF_DIR}:/etc/letsencrypt" \
  certbot/certbot renew \
    --non-interactive \
    --quiet \
    --webroot -w /var/www/certbot
then
  echo "❌ certbot renew failed or timed out."
  exit 1
fi

echo "✅ certbot renew finished."

# -----------------------------
# Reload nginx with timeout
# -----------------------------
echo "🔁 Reloading nginx inside container: ${NGINX_CONTAINER}"

if ! timeout "${NGINX_RELOAD_TIMEOUT_SECONDS}" docker exec "${NGINX_CONTAINER}" nginx -s reload; then
  echo "❌ Failed to reload nginx (timeout or error)."
  exit 1
fi

echo "✅ nginx reloaded successfully."
echo "🎉 SSL renewal cycle completed."
