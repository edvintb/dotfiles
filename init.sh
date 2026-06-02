# Dotfiles initialization — sourced by ~/.zshrc and ~/.bashrc
# Auto-detects dotfiles location for dynamic path setup

# Handle symlinks: resolve to the actual file location
_rc_file="${BASH_SOURCE[0]:-$0}"
if [ -L "$_rc_file" ]; then
    _rc_file="$(readlink -f "$_rc_file")"
fi
DOTFILES="$(cd "$(dirname "$_rc_file")" && pwd)"
unset _rc_file

# Source secrets if available
[ -f "$DOTFILES/secrets.sh" ] && source "$DOTFILES/secrets.sh"

# source work zshrc if available
[ -f "$DOTFILES/.dotfiles-work/.zshrc" ] && source "$DOTFILES/.dotfiles-work/.zshrc"

# source venv wrapper if available
[ -f "$DOTFILES/bin/venv_wrapper" ] && source "$DOTFILES/bin/venv_wrapper"
