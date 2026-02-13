#!/bin/bash
set -e

# این اسکریپت داخل کانتینر pg-backup اجرا می‌شود

PGHOST="infta_postgres"
PGUSER="refahi"
PGDATABASES=("refahi_prod" "refahi_stage")
BACKUP_DIR="/backup"

INTERVAL_SECONDS=21600  # هر 6 ساعت

echo "Postgres backup service started..."

while true; do
  TS=$(date +"%Y%m%d-%H%M%S")
  for DB in "${PGDATABASES[@]}"; do
    FILE="${BACKUP_DIR}/${DB}-${TS}.dump"
    echo "📦 Backing up database: $DB -> $FILE"
    pg_dump -h "$PGHOST" -U "$PGUSER" -Fc "$DB" > "$FILE"
  done

  echo "✅ Backup cycle complete. Sleeping for ${INTERVAL_SECONDS}s..."
  sleep "${INTERVAL_SECONDS}"
done
