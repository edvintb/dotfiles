#!/bin/bash
# Test rate limiting behavior
# Notifications within 3 seconds of each other should be skipped

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/../claude-notify.sh"
LOG_FILE="$HOME/.claude/logs/notifications.log"

echo "=== Rate Limit Test ==="
echo ""

# Clear rate limit
rm -f ~/.claude/logs/.last_notification

echo "[1] Sending first notification..."
echo '{"notification_type":"test","message":"First notification"}' | "$NOTIFY_SCRIPT"
echo "    Sent!"

echo ""
echo "[2] Sending second notification immediately (should be rate-limited)..."
echo '{"notification_type":"test","message":"Second notification - should be skipped"}' | "$NOTIFY_SCRIPT"
echo "    Sent (check if rate-limited)!"

echo ""
echo "[3] Waiting 4 seconds..."
sleep 4

echo ""
echo "[4] Sending third notification (should succeed)..."
echo '{"notification_type":"test","message":"Third notification - should work"}' | "$NOTIFY_SCRIPT"
echo "    Sent!"

echo ""
echo "=== Last 5 log entries ==="
tail -5 "$LOG_FILE"
