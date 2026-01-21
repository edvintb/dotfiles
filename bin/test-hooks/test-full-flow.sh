#!/bin/bash
# Test the full notification flow: send -> wait -> dismiss
# This simulates the real Claude Code behavior

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use consistent notification ID for send/dismiss pairing
NOTIF_ID="claude-test-$$"

echo "=== Full Notification Flow Test ==="
echo ""

# Step 1: Send notification with custom ID
echo "[1/3] Sending notification (ID: $NOTIF_ID)..."

# Clear rate limit file to ensure notification sends
rm -f ~/.claude/logs/.last_notification

# Build notification manually with our test ID
TITLE="[$(hostname -s)] idle_prompt"
MESSAGE="Test: Claude is waiting for input"

if [ -e /dev/tty ]; then
    if [ -n "$TMUX" ]; then
        printf '\ePtmux;\e\e]99;i=%s:d=0;%s\e\e\\\e\\' "$NOTIF_ID" "$TITLE" > /dev/tty
        printf '\ePtmux;\e\e]99;i=%s:d=1:p=body;%s\e\e\\\e\\' "$NOTIF_ID" "$MESSAGE" > /dev/tty
    else
        printf '\e]99;i=%s:d=0;%s\e\\' "$NOTIF_ID" "$TITLE" > /dev/tty
        printf '\e]99;i=%s:d=1:p=body;%s\e\\' "$NOTIF_ID" "$MESSAGE" > /dev/tty
    fi
    echo "      Notification sent!"
fi

# Step 2: Wait
echo ""
echo "[2/3] Waiting 3 seconds (notification should be visible)..."
sleep 3

# Step 3: Dismiss
echo ""
echo "[3/3] Dismissing notification..."
if [ -e /dev/tty ]; then
    if [ -n "$TMUX" ]; then
        printf '\ePtmux;\e\e]99;i=%s:p=close;\e\e\\\e\\' "$NOTIF_ID" > /dev/tty
    else
        printf '\e]99;i=%s:p=close;\e\\' "$NOTIF_ID" > /dev/tty
    fi
    echo "      Dismiss command sent!"
fi

echo ""
echo "=== Test Complete ==="
