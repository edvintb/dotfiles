#!/bin/bash
# Test script for Claude Code terminal bell notifications
# Run this directly in your terminal

echo "Sending test terminal bell notification..."
echo '{"notification_type":"test_notification","message":"Terminal bell test - you should hear a beep and see the title change!"}' | ~/bin-personal/claude-terminal-bell.sh

echo ""
echo "Notification sent!"
echo "You should have:"
echo "  - Heard a terminal bell/beep"
echo "  - Seen the terminal title change"
echo "  - Seen a brief visual flash"
echo ""
echo "Check the log: tail ~/.claude/logs/notifications.log"
