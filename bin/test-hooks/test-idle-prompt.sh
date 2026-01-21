#!/bin/bash
# Test the idle_prompt hook in isolation
# Simulates what Claude Code sends when it becomes idle

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/../claude-notify.sh"

echo "Testing idle_prompt hook..."
echo '{"notification_type":"idle_prompt","message":"Claude is waiting for your input"}' | "$NOTIFY_SCRIPT"

echo "Check for notification. Log at ~/.claude/logs/notifications.log"
