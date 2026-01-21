#!/bin/bash
# Test the user_prompt_submit hook (notification dismissal) in isolation
# Uses a custom notification ID since we're not running under Claude

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use a test-specific notification ID
NOTIF_ID="claude-test-$$"

echo "Dismissing notification with ID: $NOTIF_ID"

if [ -e /dev/tty ]; then
    if [ -n "$TMUX" ]; then
        printf '\ePtmux;\e\e]99;i=%s:p=close;\e\e\\\e\\' "$NOTIF_ID" > /dev/tty
    else
        printf '\e]99;i=%s:p=close;\e\\' "$NOTIF_ID" > /dev/tty
    fi
    echo "Dismiss command sent."
else
    echo "Error: /dev/tty not available"
fi
