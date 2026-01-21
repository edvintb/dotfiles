#!/bin/bash
# Test the permission_prompt hook in isolation
# Simulates what Claude Code sends when requesting permission

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/../claude-notify.sh"

echo "Testing permission_prompt hook..."
echo '{"notification_type":"permission_prompt","message":"Claude wants to run: rm -rf node_modules"}' | "$NOTIFY_SCRIPT"

echo "Check for notification. Log at ~/.claude/logs/notifications.log"
