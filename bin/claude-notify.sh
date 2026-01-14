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

# Send notification via Kitty escape sequence (OSC 99)
# This works over SSH and displays as a desktop notification
if [ -n "$MESSAGE" ]; then
    # Kitty notification format
    printf '\x1b]99;i=1:d=0;Claude Code\x1b\\'
    printf '\x1b]99;i=1:d=1:p=title;Claude Code - %s\x1b\\' "$TYPE"
    printf '\x1b]99;i=1:d=1:p=body;%s\x1b\\' "$MESSAGE"
    printf '\x1b]99;i=1:d=2;\x1b\\'

    # Also ring the terminal bell for attention
    printf '\a'
fi

exit 0
