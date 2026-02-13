# Refahi Server Bootstrap & Infrastructure Guide

این راهنما تمام مراحل راه‌اندازی صفر تا صد سرور Refahi را روی AlmaLinux (یا توزیع‌های RHEL-based مشابه) پوشش می‌دهد؛ از نصب پیش‌نیازها تا ساخت شبکه‌ها، استک‌ها، Nginx، SSL، Certbot و Cronjobهای تمدید خودکار.

> فرض می‌کنیم ریشه ریپوی `refahi-infra` روی سرور در مسیر زیر است:
>
> ```bash
> /opt/refahi-infra
> ```
>
> و تمام دیتاهای پایدار (دیتابیس، لاگ، سرتیفیکیت و …) در مسیر:
>
> ```bash
> /opt/refahi-data
> ```

ساختار هدف:

- **Stacks (Compose projects):**
  - `refahi_infra` → زیرساخت مشترک (Postgres, Redis, RabbitMQ, Nginx, Certbot, Portainer, PgAdmin, …)
  - `refahi_prod` → سرویس‌های محیط Production (در حال حاضر WebApp)
  - `refahi_stage` → سرویس‌های محیط Stage (در حال حاضر WebApp)
- **Docker Networks:**
  - `refahi_infra_net`
  - `refahi_prod_net`
  - `refahi_stage_net`

- **دامنه‌ها (نمونه):**
  - `refahiplus.com`, `www.refahiplus.com` → محیط Production
  - `stage.refahiplus.com` → محیط Stage
  - `refahiplus.xyz` → دامنه اضافه (به انتخاب شما، معمولاً به Prod وصل می‌شود)

---

## 1. پیش‌نیازهای سیستم

### 1.1. آپدیت سیستم

```bash
sudo dnf update -y
```

### 1.2. نصب ابزارهای پایه

```bash
sudo dnf install -y \
  git curl wget vim nano \
  ca-certificates \
  tar gzip \
  python3 python3-pip
```

### 1.3. تنظیم Timezone (در صورت نیاز)

```bash
sudo timedatectl set-timezone Europe/Berlin   # یا هر تایم‌زون مورد نظر
timedatectl status
```

---

## 2. نصب Docker و Docker Compose Plugin

### 2.1. نصب Docker Engine

```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

sudo dnf install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker
```

### 2.2. اضافه کردن کاربر به گروه docker (اختیاری)

```bash
sudo usermod -aG docker $USER
# سپس یکبار logout / login کنید
```

### 2.3. بررسی صحت نصب

```bash
docker version
docker compose version
```

---

## 3. ساخت مسیرهای پروژه و دیتا

### 3.1. ساخت فولدرهای اصلی

```bash
sudo mkdir -p /opt/refahi-infra
sudo mkdir -p /opt/refahi-data

# دسترسی‌ها (در صورت استفاده از کاربر غیر-root)
sudo chown -R root:root /opt/refahi-infra
sudo chown -R root:root /opt/refahi-data
```

### 3.2. ساخت ساختار دیتای پایدار

```bash
sudo mkdir -p \
  /opt/refahi-data/postgres/data \
  /opt/refahi-data/postgres/backup \
  /opt/refahi-data/pgadmin \
  /opt/refahi-data/redis \
  /opt/refahi-data/rabbitmq \
  /opt/refahi-data/certbot/conf \
  /opt/refahi-data/certbot/www \
  /opt/refahi-data/nginx/logs
```

---

## 4. کلون کردن ریپو `refahi-infra`

```bash
cd /opt
sudo git clone <YOUR_REPO_URL> refahi-infra
cd /opt/refahi-infra
```

> `<YOUR_REPO_URL>` را با URL واقعی ریپوی GitHub/GitLab خود جایگزین کنید.

ساختار پوشه‌ها (توافق‌شده):

```text
/opt/refahi-infra
  ├── docker
  │   ├── infra
  │   │   ├── postgres.yml
  │   │   ├── redis.yml
  │   │   ├── rabbitmq.yml
  │   │   ├── portainer.yml
  │   │   ├── pgadmin.yml
  │   │   ├── reverse-proxy.yml   # nginx + certbot
  │   ├── prod
  │   │   └── webapp.yml
  │   └── stage
  │       └── webapp.yml
  ├── nginx
  │   ├── nginx.conf
  │   └── conf
  │       └── conf.d
  ├── certbot
  │   ├── get-certs-first-time.sh
  │   ├── renew-certs.sh
  │   └── scripts (در صورت نیاز)
  └── deploy-agent
      ├── app.py
      ├── deploy.sh
      ├── requirements.txt
      └── refahi-deploy-agent.service
```

---

## 5. ساخت Docker Networks

سه شبکه‌ی اصلی (shared بین استک‌ها):

```bash
docker network create refahi_infra_net
docker network create refahi_prod_net
docker network create refahi_stage_net

docker network ls | grep refahi
```

انتظار داریم ببینیم:

```text
refahi_infra_net
refahi_prod_net
refahi_stage_net
```

---

## 6. راه‌اندازی استک زیرساخت (`refahi_infra`)

### 6.1. Postgres + Backup

فایل: `docker/infra/postgres.yml`  
(فرض بر این است که قبلاً تنظیم شده و مسیر دیتا روی `/opt/refahi-data/postgres` است.)

راه‌اندازی:

```bash
cd /opt/refahi-infra

docker compose -p refahi_infra -f docker/infra/postgres.yml up -d
```

### 6.2. Redis

```bash
docker compose -p refahi_infra -f docker/infra/redis.yml up -d
```

### 6.3. RabbitMQ

```bash
docker compose -p refahi_infra -f docker/infra/rabbitmq.yml up -d
```

### 6.4. PgAdmin

```bash
docker compose -p refahi_infra -f docker/infra/pgadmin.yml up -d
```

### 6.5. Portainer

```bash
docker compose -p refahi_infra -f docker/infra/portainer.yml up -d
```

### 6.6. Reverse Proxy (Nginx + Certbot)

```bash
docker compose -p refahi_infra -f docker/infra/reverse-proxy.yml up -d
```

بعد از این مرحله:

```bash
docker compose ls
docker ps
```

باید حداقل کانتینرهای زیر را ببینید:

- `infra_nginx`
- `infra_certbot`
- `infra_postgres`
- `infra_redis`
- `infra_rabbitmq`
- `infra_pgadmin`
- `infra_portainer`

---

## 7. تنظیم Nginx

### 7.1. فایل اصلی:

مسیر روی میزبان:

```bash
/opt/refahi-infra/nginx/nginx.conf
```

این فایل در کانتینر روی `/etc/nginx/nginx.conf` mount می‌شود.

نمونه ساختار:

```nginx
user  nginx;
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    include /etc/nginx/conf.d/*.conf;
}
```

### 7.2. فایل‌های virtual host

روی میزبان:

```bash
/opt/refahi-infra/nginx/conf/conf.d/
```

نمونه فایل‌ها:

- `default.conf` → هندل ACME روی HTTP و 404 برای بقیه
- `prod-http.conf` → HTTP → HTTPS برای `refahiplus.com` و `www.refahiplus.com`
- `prod.conf` → HTTPS + Proxy به `webapp_prod` و `webapi_prod`
- `stage-http.conf` → HTTP → HTTPS برای `stage.refahiplus.com`
- `stage.conf` → HTTPS + Proxy به `webapp_stage` و `webapi_stage`
- `xyz-http.conf` + `xyz.conf` → برای `refahiplus.xyz` (در صورت نیاز)

الگوی مشترک برای ACME:

```nginx
location /.well-known/acme-challenge/ {
    root /var/www/certbot;
}
```

برای Proxy به WebApp/Api (مثال Prod):

```nginx
location /api/ {
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_read_timeout 60s;
    proxy_pass http://webapi_prod:8080;
}

location / {
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_pass http://webapp_prod:80;

    default_type application/wasm;
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    add_header Pragma "no-cache";
    add_header Expires 0;
}
```

> مهم: کانتینر `infra_nginx` باید عضو سه شبکه باشد:  
> `refahi_infra_net`, `refahi_prod_net`, `refahi_stage_net`  
> این کار در `reverse-proxy.yml` انجام می‌شود.

پس از هر تغییر در کانفیگ Nginx:

```bash
docker exec infra_nginx nginx -t
docker restart infra_nginx
```

---

## 8. ساخت اولیه SSL Certificates

### 8.1. پیش‌نیاز DNS

برای هر دامنه باید رکورد `A` روی IP سرور تنظیم شده باشد.  
اگر Cloudflare استفاده می‌کنید، **برای گرفتن اولین cert حتماً Proxy را خاموش (DNS only)** کنید.

مثال دامنه‌ها:

- `refahiplus.com`
- `www.refahiplus.com`
- `stage.refahiplus.com`
- `refahiplus.xyz`

### 8.2. اجرای اسکریپت ساخت اولیه

روی سرور:

```bash
cd /opt/refahi-infra/certbot

bash get-certs-first-time.sh \
  refahiplus.com \
  www.refahiplus.com \
  stage.refahiplus.com \
  refahiplus.xyz
```

پس از موفقیت، سرتیفیکیت‌ها در کانفیگ data قرار می‌گیرند:

```bash
/opt/refahi-data/certbot/conf/live/<domain>/
```

مثال:

- `/opt/refahi-data/certbot/conf/live/refahiplus.com/`
- `/opt/refahi-data/certbot/conf/live/stage.refahiplus.com/`
- `/opt/refahi-data/certbot/conf/live/refahiplus.xyz/`

### 8.3. Restart Nginx

```bash
docker restart infra_nginx
```

تست:

```bash
curl -k https://refahiplus.com
curl -k https://stage.refahiplus.com
curl -k https://refahiplus.xyz
```

---

## 9. راه‌اندازی استک‌های Prod و Stage

### 9.1. استک Prod (`refahi_prod`)

فایل: `docker/prod/webapp.yml`  

نمونه (حداقل):

```yaml
services:
  webapp:
    image: ghcr.io/refahigroup/refahi-webapp:prod
    container_name: prod_webapp
    restart: always
    networks:
      - refahi_prod_net

networks:
  refahi_prod_net:
    external: true
```

راه‌اندازی:

```bash
cd /opt/refahi-infra
docker compose -p refahi_prod -f docker/prod/webapp.yml up -d
```

### 9.2. استک Stage (`refahi_stage`)

فایل: `docker/stage/webapp.yml`  

```yaml
services:
  webapp:
    image: ghcr.io/refahigroup/refahi-webapp:stage
    container_name: stage_webapp
    restart: always
    networks:
      - refahi_stage_net

networks:
  refahi_stage_net:
    external: true
```

راه‌اندازی:

```bash
cd /opt/refahi-infra
docker compose -p refahi_stage -f docker/stage/webapp.yml up -d
```

تست از سرور:

```bash
curl -k https://refahiplus.com
curl -k https://stage.refahiplus.com
```

---

## 10. Deploy Agent (FastAPI + Systemd)

### 10.1. نصب وابستگی‌ها

```bash
cd /opt/refahi-infra/deploy-agent
pip3 install -r requirements.txt
```

### 10.2. فایل Environment

```bash
sudo tee /etc/refahi-deploy-agent.env >/dev/null <<EOF
DEPLOY_TOKEN=<YOUR_LONG_RANDOM_TOKEN>
EOF
```

این توکن باید در GitHub Actions هم در secret متناظر (مثلاً `DEPLOY_AGENT_TOKEN`) قرار گیرد.

### 10.3. فایل Systemd Service

فایل `/etc/systemd/system/refahi-deploy-agent.service`:

```ini
[Unit]
Description=Refahi Deploy Agent (FastAPI)
After=network.target docker.service
Requires=docker.service

[Service]
WorkingDirectory=/opt/refahi-infra/deploy-agent
EnvironmentFile=/etc/refahi-deploy-agent.env
ExecStart=/usr/bin/env uvicorn app:app --host 0.0.0.0 --port 3142
Restart=always
RestartSec=5
User=root
Group=root

[Install]
WantedBy=multi-user.target
```

بارگذاری و فعال‌سازی:

```bash
sudo systemctl daemon-reload
sudo systemctl enable refahi-deploy-agent
sudo systemctl start refahi-deploy-agent
sudo systemctl status refahi-deploy-agent
```

### 10.4. تست Health

```bash
curl http://127.0.0.1:3142/health
# پاسخ: {"status":"ok"}
```

---

## 11. تنظیم Cronjob برای Auto-Renewal SSL

### 11.1. اسکریپت renew-certs

فایل: `/opt/refahi-infra/certbot/renew-certs.sh`

نمونه پیشنهادی:

```bash
#!/bin/bash
set -e

echo "🔁 Starting SSL renew process..."

# انتخاب کانتینر Nginx
if docker ps --format '{{.Names}}' | grep -q "^infra_nginx$"; then
  NGINX_CONTAINER="infra_nginx"
else
  echo "❌ Nginx container not found!"
  exit 1
fi

echo "🔐 Running certbot renew..."
docker exec infra_certbot certbot renew --non-interactive

echo "✅ certbot renew finished."
echo "🔁 Reloading nginx inside container: $NGINX_CONTAINER"
docker exec "$NGINX_CONTAINER" nginx -s reload
echo "✅ NGINX reloaded."
```

فراموش نکنید:

```bash
chmod +x /opt/refahi-infra/certbot/renew-certs.sh
```

### 11.2. فایل Cron در `/etc/cron.d/refahi-certbot`

```bash
sudo tee /etc/cron.d/refahi-certbot >/dev/null <<EOF
# Renew Let's Encrypt certs daily at 03:00
0 3 * * * root /opt/refahi-infra/certbot/renew-certs.sh >> /var/log/certbot-renew.log 2>&1
EOF

sudo chmod 644 /etc/cron.d/refahi-certbot
```

### 11.3. اطمینان از اجرای crond

```bash
sudo systemctl enable crond
sudo systemctl start crond
sudo systemctl status crond
```

### 11.4. تست دستی

```bash
bash /opt/refahi-infra/certbot/renew-certs.sh
```

و برای Dry-Run Certbot:

```bash
docker exec infra_certbot certbot renew --dry-run
```

---

## 12. چک‌لیست نهایی راه‌اندازی یک سرور جدید

۱. نصب AlmaLinux + بروزرسانی سیستم  
۲. نصب Docker + Docker Compose Plugin  
۳. ساخت `/opt/refahi-infra` و `/opt/refahi-data`  
۴. کلون کردن ریپوی `refahi-infra` در `/opt/refahi-infra`  
۵. ساخت شبکه‌ها:
   - `refahi_infra_net`
   - `refahi_prod_net`
   - `refahi_stage_net`
۶. بالا آوردن استک‌های زیرساخت (`refahi_infra`):
   - postgres.yml
   - redis.yml
   - rabbitmq.yml
   - pgadmin.yml
   - portainer.yml
   - reverse-proxy.yml
۷. تنظیم Nginx (nginx.conf + conf.d/*.conf)  
۸. گرفتن SSL اولیه برای تمام دامنه‌ها با `get-certs-first-time.sh`  
۹. راه‌اندازی استک‌های Prod و Stage (`refahi_prod` و `refahi_stage`)  
۱۰. راه‌اندازی Deploy Agent (uvicorn + systemd)  
۱۱. تنظیم Cronjob برای تجدید خودکار SSL (`renew-certs.sh` + `/etc/cron.d/refahi-certbot`)  
۱۲. تست نهایی:
    - `curl http://localhost`
    - `curl -k https://refahiplus.com`
    - `curl -k https://stage.refahiplus.com`
    - `curl -k https://refahiplus.xyz`
    - `curl http://127.0.0.1:3142/health`

اگر تمام این موارد بدون خطا انجام شود، سرور Refahi آماده‌ی استفاده‌ی Production و اتصال CI/CD خواهد بود.
