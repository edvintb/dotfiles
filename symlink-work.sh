#!/usr/bin/env zsh

link() {
    local src="$1"
    local dst="$2"

    if [[ -L $dst ]]; then
        rm $dst
    fi

    ln -s $src $dst
}

if [ ! -d ~/.dotfiles/.dotfiles-work ]; then
    echo "The directory ./.dotfiles-work does not exist."
    exit 0
fi

# directories
link $HOME/.dotfiles/.dotfiles-work/bin $HOME/bin-work

