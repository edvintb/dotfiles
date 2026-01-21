# bin Scripts

Personal utility scripts added to `$PATH`.

## Claude Code Notifications

### claude-notify.sh

Primary notification script for Claude Code using Kitty's OSC 99 protocol.

**Features:**
- Sends macOS system notifications via Kitty terminal
- Works over SSH (notifications appear on local machine)
- Includes machine name in notification title
- Automatically handles tmux passthrough
- Rate-limited (3 seconds minimum between notifications) to prevent macOS suppression
- Logs all notifications to `~/.claude/logs/notifications.log`

**Format:**
- Title: `[machine-name] notification_type`
- Body: The notification message

**Usage:**
Configured in `~/.claude/settings.json`:
```json
"hooks": {
  "Notification": [
    {
      "matcher": "permission_prompt",
      "hooks": [{"type": "command", "command": "$HOME/bin-personal/claude-notify.sh"}]
    },
    {
      "matcher": "idle_prompt",
      "hooks": [{"type": "command", "command": "$HOME/bin-personal/claude-notify.sh"}]
    }
  ]
}
```

### claude-terminal-bell.sh

Alternative notification script using terminal bells and visual alerts.

**Features:**
- Terminal bell/beep (audible alert)
- Updates terminal window title
- Visual flash (reverse video)
- Not rate-limited by macOS
- No dependency on Notification Center

**Use cases:**
- Fallback if OSC 99 stops working
- When terminal is always visible and you want instant feedback
- Testing without spamming Notification Center

**Limitations:**
- Only works if terminal is visible/focused
- No notification history
- Easier to miss than system notifications

### Test Scripts

- `test-notification.sh` - Test the OSC 99 notification system
- `test-terminal-bell.sh` - Test the terminal bell notification system

Run these to verify notifications are working correctly.

## Technical Details

### OSC 99 Protocol

Kitty's notification protocol format:
```
\e]99;i=<id>:d=<done>;title\e\\
\e]99;i=<id>:d=<done>:p=body;body-text\e\\
```

- `i=<id>` - Notification identifier (same ID for title and body)
- `d=0` - Incomplete (waiting for more data)
- `d=1` - Done (display notification now)
- `p=body` - Payload type (body text)

### Tmux Passthrough

When running inside tmux, escape sequences must be wrapped:
```
\ePtmux;\e<original-sequence>\e\\
```

The script automatically detects tmux via `$TMUX` environment variable.
