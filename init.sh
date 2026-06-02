# Dotfiles initialization — sourced by ~/.zshrc and ~/.bashrc

# SSH agent forwarding: maintain stable symlink to current socket (SSH sessions only)
if [ -n "$SSH_CONNECTION" ] && [ -n "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/ssh_auth_sock" ]; then
    old_target=$(readlink "$HOME/.ssh/ssh_auth_sock" 2>/dev/null)
    ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/ssh_auth_sock"
    echo "[init.sh] SSH socket: $old_target -> $SSH_AUTH_SOCK" >&2
fi
[ -n "$SSH_CONNECTION" ] && export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"

# Source user secrets if they exist
[ -f "$HOME/.dotfiles/secrets.sh" ] && source "$HOME/.dotfiles/secrets.sh"
