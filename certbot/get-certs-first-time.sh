#!/bin/bash
set -euo pipefail

# استفاده:
#   bash get-certs-first-time.sh refahiplus.com www.refahiplus.com stage.refahiplus.com

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <domain1> [domain2] [domain3] ..."
  exit 1
fi

DATA_BASE="/opt/refahi-data/certbot"

WEBROOT="${DATA_BASE}/www"
CONF_DIR="${DATA_BASE}/conf"

echo "📁 Ensuring certbot data directories exist..."
mkdir -p "$WEBROOT" "$CONF_DIR"

DOMAINS=("$@")

for DOMAIN in "${DOMAINS[@]}"; do
  echo "🔐 Requesting initial certificate for: $DOMAIN"

  docker run --rm \
    -v "${WEBROOT}:/var/www/certbot" \
    -v "${CONF_DIR}:/etc/letsencrypt" \
    certbot/certbot certonly \
      --non-interactive \
      --agree-tos \
      --email admin@refahiplus.com \
      --webroot -w /var/www/certbot \
      -d "$DOMAIN"

  echo "✅ Certificate obtained for: $DOMAIN"
done

echo "ℹ️ Certificates are stored under: ${CONF_DIR}/live/<domain>/"
echo "ℹ️ Now restart nginx: docker restart infta_nginx"
