#!/usr/bin/env zsh

link() {
    local src="$1"
    local dst="$2"

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
        echo "⚠ Warning: $dst exists but is not a symlink. Skipping."
        return 1
    fi

    ln -s "$src" "$dst"
    echo "✓ Created symlink: $dst -> $src"
}

# files
link $HOME/.dotfiles/.zshrc $HOME/.zshrc
link $HOME/.dotfiles/.bashrc $HOME/.bashrc
link $HOME/.dotfiles/.gitconfig $HOME/.gitconfig

# claude
mkdir -p $HOME/.claude
link $HOME/.dotfiles/claude/settings.json $HOME/.claude/settings.json
link $HOME/.dotfiles/claude/CLAUDE.md $HOME/.claude/CLAUDE.md

# .config
link $HOME/.dotfiles/nvim $HOME/.config/nvim
link $HOME/.dotfiles/tmux $HOME/.config/tmux
link $HOME/.dotfiles/lazygit $HOME/.config/lazygit
link $HOME/.dotfiles/lf $HOME/.config/lf
link $HOME/.dotfiles/kitty $HOME/.config/kitty
link $HOME/.dotfiles/sway $HOME/.config/sway
link $HOME/.dotfiles/i3 $HOME/.config/i3
link $HOME/.dotfiles/i3status $HOME/.config/i3status
link $HOME/.dotfiles/redshift $HOME/.config/redshift
link $HOME/.dotfiles/aerospace $HOME/.config/aerospace
link $HOME/.dotfiles/karabiner $HOME/.config/karabiner

# directories
link $HOME/.dotfiles/bin $HOME/bin-personal
# make obsidian vault
mkdir -p $HOME/vault

# link the tmux
link $HOME/.dotfiles/tmux/tmux.conf $HOME/.tmux.conf
