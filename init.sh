# Dotfiles initialization — sourced by ~/.zshrc and ~/.bashrc

# SSH agent: symlink is maintained by ~/.ssh/rc on every SSH connection
# Testing: comment out to see if ~/.ssh/rc alone is sufficient
# export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"

# Source user secrets if they exist
[ -f "$HOME/.dotfiles/secrets.sh" ] && source "$HOME/.dotfiles/secrets.sh"
