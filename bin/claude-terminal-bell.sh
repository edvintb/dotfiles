#!/bin/bash
# Claude Code notification script using terminal bells and visual alerts
# Not rate-limited by macOS

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

if [ -n "$MESSAGE" ]; then
    # Get machine name
    MACHINE=$(hostname -s)

    # Terminal bell
    printf '\a'

    # Update terminal title with notification
    # This works in most terminals including Kitty, tmux, etc.
    printf '\e]2;🔔 [%s] Claude Code - %s: %s\a' "$MACHINE" "$TYPE" "$MESSAGE"

    # Optional: Flash the terminal using visual bell escape sequence
    # This makes the terminal briefly change colors/flash
    printf '\e[?5h'  # Enable reverse video (visual bell)
    sleep 0.1
    printf '\e[?5l'  # Disable reverse video

    # Optional: Print a visible notification in the terminal
    # Uncomment if you want in-terminal notifications too
    # echo ""
    # echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    # echo "🔔 Claude Code Notification"
    # echo "Type: $TYPE"
    # echo "Message: $MESSAGE"
    # echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    # echo ""
fi

exit 0
