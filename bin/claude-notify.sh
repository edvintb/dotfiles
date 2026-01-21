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
# Write directly to /dev/tty to bypass Claude Code's output capture
# Format: \e]99;metadata;payload\e\\
# Title has d=0 (incomplete), body has d=1 (display now)
if [ -n "$MESSAGE" ] && [ -e /dev/tty ]; then
    # Get machine name
    MACHINE=$(hostname -s)

    # Build title and body
    TITLE="[$MACHINE] $TYPE"

    # Find the Claude Code process by walking up the process tree
    # This works whether hooks are run directly or via intermediate shell
    find_claude_pid() {
        local pid=$PPID
        while [ "$pid" -gt 1 ]; do
            local comm=$(ps -p "$pid" -o comm= 2>/dev/null)
            if [ "$comm" = "claude" ]; then
                echo "$pid"
                return
            fi
            pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
        done
        # Fallback to PPID if claude not found
        echo "$PPID"
    }
    CLAUDE_PID=$(find_claude_pid)
    NOTIF_ID="claude-$CLAUDE_PID"

    # Check if we're inside tmux
    if [ -n "$TMUX" ]; then
        # Wrap with tmux DCS passthrough
        # Send title (d=0 means incomplete, waiting for more)
        printf '\ePtmux;\e\e]99;i=%s:d=0;%s\e\e\\\e\\' "$NOTIF_ID" "$TITLE" > /dev/tty
        # Send body (d=1 means display now)
        printf '\ePtmux;\e\e]99;i=%s:d=1:p=body;%s\e\e\\\e\\' "$NOTIF_ID" "$MESSAGE" > /dev/tty
    else
        # Direct OSC 99 escape sequences
        # Send title (d=0 means incomplete)
        printf '\e]99;i=%s:d=0;%s\e\\' "$NOTIF_ID" "$TITLE" > /dev/tty
        # Send body (d=1 means display now)
        printf '\e]99;i=%s:d=1:p=body;%s\e\\' "$NOTIF_ID" "$MESSAGE" > /dev/tty
    fi
fi

exit 0
