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

# Rate limiting: only send if last notification was >3 seconds ago
RATE_LIMIT_FILE="$LOG_DIR/.last_notification"
CURRENT_TIME=$(date +%s)
if [ -f "$RATE_LIMIT_FILE" ]; then
    LAST_TIME=$(cat "$RATE_LIMIT_FILE")
    TIME_DIFF=$((CURRENT_TIME - LAST_TIME))
    if [ "$TIME_DIFF" -lt 3 ]; then
        # Too soon, skip notification but log it
        echo "[$TIMESTAMP] [RATE_LIMITED] Skipped notification" >> "$LOG_FILE"
        exit 0
    fi
fi
echo "$CURRENT_TIME" > "$RATE_LIMIT_FILE"

# Send notification using raw Kitty OSC 99 escape sequences
# Format: \e]99;metadata;payload\e\\
# Title has d=0 (incomplete), body has d=1 (display now)
if [ -n "$MESSAGE" ]; then
    # Get machine name
    MACHINE=$(hostname -s)

    # Build title and body
    TITLE="[$MACHINE] $TYPE"

    # Use a notification ID based on process ID
    NOTIF_ID="claude-$$"

    # Check if we're inside tmux
    if [ -n "$TMUX" ]; then
        # Wrap with tmux DCS passthrough
        # Send title (d=0 means incomplete, waiting for more)
        printf '\ePtmux;\e\e]99;i=%s:d=0;%s\e\e\\\e\\' "$NOTIF_ID" "$TITLE"
        # Send body (d=1 means display now)
        printf '\ePtmux;\e\e]99;i=%s:d=1:p=body;%s\e\e\\\e\\' "$NOTIF_ID" "$MESSAGE"
    else
        # Direct OSC 99 escape sequences
        # Send title (d=0 means incomplete)
        printf '\e]99;i=%s:d=0;%s\e\\' "$NOTIF_ID" "$TITLE"
        # Send body (d=1 means display now)
        printf '\e]99;i=%s:d=1:p=body;%s\e\\' "$NOTIF_ID" "$MESSAGE"
    fi
fi

exit 0
