#!/usr/bin/env zsh

# Auto-detect dotfiles repo location (directory containing this script)
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
echo "Dotfiles location: $DOTFILES"
echo ""

link() {
    local src="$1"
    local dst="$2"
    local make_executable="${3:-false}"

    # Check if symlink already exists and points to the correct location
    if [[ -L $dst ]]; then
        local current_target=$(readlink "$dst")
        if [[ "$current_target" == "$src" ]]; then
            echo "✓ Symlink already exists: $dst -> $src"
            return 0
        else
            echo "⟳ Updating symlink: $dst"
            echo "  Old target: $current_target"
            echo "  New target: $src"
            rm "$dst"
        fi
    elif [[ -e $dst ]]; then
        local backup="${dst}.backup"
        echo "⟳ Backing up existing: $dst -> $backup"
        mv "$dst" "$backup"
    fi

    ln -s "$src" "$dst"
    [ "$make_executable" = "true" ] && chmod +x "$dst"
    echo "✓ Created symlink: $dst -> $src"
}

# files
link $DOTFILES/init.sh $HOME/.dotfiles_rc true
link $DOTFILES/.zshrc $HOME/.zshrc
link $DOTFILES/.bashrc $HOME/.bashrc
link $DOTFILES/.gitconfig $HOME/.gitconfig
link $DOTFILES/vimrc $HOME/.vimrc

# claude
mkdir -p $HOME/.claude
link $DOTFILES/claude/settings.json $HOME/.claude/settings.json
link $DOTFILES/claude/CLAUDE.md $HOME/.claude/CLAUDE.md

# .config
link $DOTFILES/nvim $HOME/.config/nvim
link $DOTFILES/tmux $HOME/.config/tmux
link $DOTFILES/lazygit $HOME/.config/lazygit
link $DOTFILES/lf $HOME/.config/lf
link $DOTFILES/kitty $HOME/.config/kitty
link $DOTFILES/sway $HOME/.config/sway
link $DOTFILES/i3 $HOME/.config/i3
link $DOTFILES/i3status $HOME/.config/i3status
link $DOTFILES/redshift $HOME/.config/redshift
link $DOTFILES/aerospace $HOME/.config/aerospace
link $DOTFILES/karabiner $HOME/.config/karabiner

# ssh (for agent-forwarding socket symlink — see ssh/rc)
mkdir -p $HOME/.ssh
link $DOTFILES/ssh/rc $HOME/.ssh/rc

# directories
link $DOTFILES/bin $HOME/bin-personal
# make obsidian vault
mkdir -p $HOME/vault

# link the tmux
link $DOTFILES/tmux/tmux.conf $HOME/.tmux.conf
