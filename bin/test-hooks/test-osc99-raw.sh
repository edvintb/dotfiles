#!/bin/bash
# Raw OSC 99 test - bypasses all scripts to test terminal support directly
# Use this to verify your Kitty terminal is receiving OSC 99 correctly

NOTIF_ID="raw-test-$$"

echo "=== Raw OSC 99 Test ==="
echo "Notification ID: $NOTIF_ID"
echo ""

if [ ! -e /dev/tty ]; then
    echo "Error: /dev/tty not available"
    exit 1
fi

echo "[1] Sending raw OSC 99 notification..."

if [ -n "$TMUX" ]; then
    echo "    (tmux detected, using passthrough)"
    # Title
    printf '\ePtmux;\e\e]99;i=%s:d=0;Raw OSC 99 Test\e\e\\\e\\' "$NOTIF_ID" > /dev/tty
    # Body
    printf '\ePtmux;\e\e]99;i=%s:d=1:p=body;This is a raw OSC 99 test notification\e\e\\\e\\' "$NOTIF_ID" > /dev/tty
else
    echo "    (direct terminal)"
    # Title
    printf '\e]99;i=%s:d=0;Raw OSC 99 Test\e\\' "$NOTIF_ID" > /dev/tty
    # Body
    printf '\e]99;i=%s:d=1:p=body;This is a raw OSC 99 test notification\e\\' "$NOTIF_ID" > /dev/tty
fi

echo "    Sent!"
echo ""
read -p "Press Enter to dismiss the notification..."

echo ""
echo "[2] Dismissing..."

if [ -n "$TMUX" ]; then
    printf '\ePtmux;\e\e]99;i=%s:p=close;\e\e\\\e\\' "$NOTIF_ID" > /dev/tty
else
    printf '\e]99;i=%s:p=close;\e\\' "$NOTIF_ID" > /dev/tty
fi

echo "    Done!"
