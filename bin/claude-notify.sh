#!/bin/bash
# Claude Code notification script for Kitty terminal

# Create log directory
LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/notifications.log"

# Read JSON input from stdin
INPUT=$(cat)

# Extract message and notification type
MESSAGE=$(echo "$INPUT" | grep -o '"message":"[^"]*"' | sed 's/"message":"\(.*\)"/\1/')
TYPE=$(echo "$INPUT" | grep -o '"notification_type":"[^"]*"' | sed 's/"notification_type":"\(.*\)"/\1/')

# Log the notification
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] [$TYPE] $MESSAGE" >> "$LOG_FILE"

# Send notification via kitten notify
# Uses Kitty's built-in notification system (OSC 99 protocol)
# Works over SSH and displays on the local machine
if [ -n "$MESSAGE" ]; then
    # Use kitten notify to generate and send the notification
    # --only-print-escape-code makes it work in non-interactive contexts
    kitten notify --only-print-escape-code \
        --app-name "Claude Code" \
        --urgency normal \
        "Claude Code - $TYPE" \
        "$MESSAGE"
fi

exit 0
