# Dotfiles initialization — sourced by ~/.zshrc and ~/.bashrc

# SSH agent: ~/.ssh/rc updates the symlink on each connection, shell uses it
export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"

# Source user secrets if they exist
[ -f "$HOME/.dotfiles/secrets.sh" ] && source "$HOME/.dotfiles/secrets.sh"
