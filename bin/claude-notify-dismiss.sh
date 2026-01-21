#!/bin/bash
# Dismiss Claude Code notifications using Kitty OSC 99 close action

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

if [ -e /dev/tty ]; then
    if [ -n "$TMUX" ]; then
        # Wrap with tmux DCS passthrough
        printf '\ePtmux;\e\e]99;i=%s:p=close;\e\e\\\e\\' "$NOTIF_ID" > /dev/tty
    else
        # Direct OSC 99 close
        printf '\e]99;i=%s:p=close;\e\\' "$NOTIF_ID" > /dev/tty
    fi
fi

exit 0
