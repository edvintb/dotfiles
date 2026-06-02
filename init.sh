# Dotfiles initialization — sourced by ~/.zshrc and ~/.bashrc

# SSH agent uses a stable symlink that ~/.ssh/rc keeps updated
export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"

# Source user secrets if they exist
[ -f "$HOME/.dotfiles/secrets.sh" ] && source "$HOME/.dotfiles/secrets.sh"
