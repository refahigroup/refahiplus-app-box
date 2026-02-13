#!/bin/bash
set -euo pipefail

echo "==========================================="
echo "🚀 Refahi - AlmaLinux Bootstrap"
echo "==========================================="

echo "🔧 Updating system packages..."
dnf -y update

echo "📦 Installing required tools..."
dnf -y install yum-utils device-mapper-persistent-data lvm2

echo "🐳 Adding Docker CE repository..."
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo "🐳 Installing Docker Engine & Compose plugin..."
dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "🚀 Enabling and starting Docker service..."
systemctl enable --now docker

echo "👤 Creating 'docker' group and adding current user..."
if ! getent group docker >/dev/null 2>&1; then
  groupadd docker
fi
usermod -aG docker "${SUDO_USER:-root}" || true

echo "📁 Creating infra and data directories..."
mkdir -p /opt/refahi-infra
mkdir -p /opt/refahi-data

echo "==========================================="
echo "📦 Running init-data-directories.sh (if exists)"
if [ -f /opt/refahi-infra/scripts/init-data-directories.sh ]; then
  bash /opt/refahi-infra/scripts/init-data-directories.sh
else
  echo "⚠️ init-data-directories.sh not found (will run after cloning repo)."
fi

echo "==========================================="
echo "🧩 Running init-sysctl.sh (if exists)"
if [ -f /opt/refahi-infra/scripts/init-sysctl.sh ]; then
  bash /opt/refahi-infra/scripts/init-sysctl.sh
else
  echo "⚠️ init-sysctl.sh not found (will run after cloning repo)."
fi

echo "==========================================="
echo "🕒 Setting up Crontab Jobs"

CRON_CMD_SSL="0 3 * * * /usr/bin/bash /opt/refahi-infra/certbot/renew-certs.sh >> /var/log/certbot-renew.log 2>&1"
CRON_CMD_PG="0 4 * * * find /opt/refahi-data/backups/postgres -type f -mtime +7 -delete"

crontab -l 2>/dev/null | grep -v -F "$CRON_CMD_SSL" | grep -v -F "$CRON_CMD_PG" > /tmp/current_cron || true

echo "$CRON_CMD_SSL" >> /tmp/current_cron
echo "$CRON_CMD_PG" >> /tmp/current_cron

crontab /tmp/current_cron
rm -f /tmp/current_cron

echo "✅ Crontab updated successfully."

echo "==========================================="
echo "🔄 Configuring pull-infra.sh (if exists)..."
if [ -f /opt/refahi-infra/scripts/pull-infra.sh ]; then
  chmod +x /opt/refahi-infra/scripts/pull-infra.sh
  echo "✔ pull-infra.sh is ready to use."
else
  echo "⚠ pull-infra.sh not found (will become available after cloning repo)."
fi

echo "==========================================="
echo "🔄 Configuring reload-deploy-agent.sh (if exists)..."
if [ -f /opt/refahi-infra/scripts/reload-deploy-agent.sh ]; then
  chmod +x /opt/refahi-infra/scripts/reload-deploy-agent.sh
  echo "✔ reload-deploy-agent.sh is ready to use."
else
  echo "⚠ reload-deploy-agent.sh not found (will become available after cloning repo)."
fi

echo "==========================================="
echo "🎉 Bootstrap complete!"
echo ""
echo "➡ NEXT STEPS:"
echo ""
echo "1) LOGOUT and LOGIN again to activate docker group permissions."
echo ""
echo "2) Clone your infra repo:"
echo "     git clone https://github.com/YOUR_ORG/refahi-infra /opt/refahi-infra"
echo ""
echo "3) After cloning, run:"
echo "     bash /opt/refahi-infra/scripts/pull-infra.sh"
echo "   (This loads latest code + reloads Deploy Agent safely.)"
echo ""
echo "4) Then start the infrastructure stack:"
echo "     bash /opt/refahi-infra/scripts/up-infta.sh"
echo ""
echo "==========================================="
