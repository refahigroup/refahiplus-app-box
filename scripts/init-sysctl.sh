#!/bin/bash
set -e

REQUIRED_VALUE=262144
CONF_FILE="/etc/sysctl.d/99-elasticsearch.conf"

echo "🔍 Checking current vm.max_map_count value..."
CURRENT_VALUE=$(sysctl -n vm.max_map_count)

if [ "$CURRENT_VALUE" -eq "$REQUIRED_VALUE" ]; then
    echo "✅ vm.max_map_count is already set to $REQUIRED_VALUE"
else
    echo "⚙️  Updating vm.max_map_count to $REQUIRED_VALUE..."
    echo "vm.max_map_count=$REQUIRED_VALUE" > "$CONF_FILE"
    sysctl -p "$CONF_FILE"
    echo "✅ vm.max_map_count updated and applied."
fi

echo "🔍 Verifying final value..."
FINAL=$(sysctl -n vm.max_map_count)

if [ "$FINAL" -eq "$REQUIRED_VALUE" ]; then
    echo "🎉 Success: vm.max_map_count is correctly set."
else
    echo "❌ ERROR: vm.max_map_count could not be set correctly!"
    exit 1
fi

echo "✨ Done."
