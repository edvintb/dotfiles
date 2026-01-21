#!/bin/bash
# Test script for Claude Code notifications
# Run this directly in your Kitty terminal

echo "Sending test notification..."
echo '{"notification_type":"test_notification","message":"If you see this notification, the system is working!"}' | ~/bin-personal/claude-notify.sh

echo ""
echo "Notification sent! Check your macOS notification center (top-right corner)"
echo "If you don't see it, there may be an issue with the notification permissions."
