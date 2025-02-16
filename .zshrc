# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

# Force yourself as the system's default user
DEFAULT_USER="$(whoami)"

# autoload -U promptinit; promptinit
#
# # optionally define some options
# PURE_CMD_MAX_EXEC_TIME=10
#
# # turn on git stash status
# zstyle :prompt:pure:git:stash show yes
#
# zstyle :prompt:pure:virtualenv show no
#
# zstyle :prompt:pure:git:branch color red
#
# zstyle :prompt:pure:host color 242
#
# zstyle :prompt:pure:user color 242
#
# export CONDA_DEFAULT_ENV=""
# # conda config --set changeps1 False
#
# prompt pure

plugins=(
    git
    vi-mode
    zsh-syntax-highlighting
    zsh-autosuggestions
)

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src  # required for zsh-completions
source $ZSH/oh-my-zsh.sh

# User configuration
export PATH=$PATH:$HOME/bin
export PATH=$PATH:$HOME/bin-personal
export PATH=$PATH:$HOME/bin-work
export PATH=$PATH:/Applications/kitty.app/Contents/MacOS
export PATH=/opt/homebrew/opt/llvm/bin:$PATH  # want to use this version of clang first

# Add path to custom binaries -- apt in old ubuntu versions won't download updated versions
# export PATH=$PATH:$HOME/neovim/build/bin
export PATH=$PATH:$HOME/fzf/bin
export PATH=$PATH:$HOME/delta/target/release
export PATH=$HOME/.dotfiles/tmux-3.5/tmux:$PATH

# set the tmux tmpdir environment variable
export TMUX_TMPDIR=/tmp
export TERM="xterm-256color"  # Or export TERM="xterm-kitty"

# Set the XDG_CONFIG_HOME env variable
# export XDG_CONFIG_HOME=$HOME/.config/nvim
# export XDG_CONFIG_HOME=""

# source private config
ZSHRC_PRIVATE=~/.dotfiles/zshrc_private
if [[ -f $ZSHRC_PRIVATE ]]; then
    source $ZSHRC_PRIVATE
fi

# source work zshrc
ZSHRC_WORK=$HOME/.dotfiles/.dotfiles-work/.zshrc
if [[ -f $ZSHRC_WORK ]]; then
    source $ZSHRC_WORK
fi

# source the virtual env wrapper
source $HOME/.dotfiles/bin/venv_wrapper

# enable fzf completion
source <(fzf --zsh)

# aliases
alias t=tmux
alias n=nvim
alias p=python3
alias sw=swatch
alias tms=tmux-sessionizer
alias kssh="kitty +kitten ssh"
alias k='kubectl'
alias gs='bash ~/bin-personal/git_status'
alias glog='git log --graph --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%an%C(reset)%C(bold yellow)%d%C(reset) %C(dim white)- %s%C(reset)" --all'
alias prune-branches='git fetch --prune && git branch -vv | grep ": gone]" | awk "{print \$1}" | xargs -r git branch -D'
alias gd='git diff'
alias ga='git add'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
cl() {
  cd "$1" && ls
}

# reve aliases
alias qu-install="pip3 install git+ssh://git@github.com/reve-ai/queryfile-util.git"

# no beep
unsetopt BEEP LIST_BEEP

# only use less when the output is taller than the height of the terminal
export LESS="-FR"

# configure autosuggestions with C-y to complete
# Define a custom widget to accept autosuggestion
function accept-autosuggestion-widget() {
    zle autosuggest-accept
}
zle -N accept-autosuggestion-widget  # Register the widget with ZLE
bindkey '^Y' accept-autosuggestion-widget  # Bind Ctrl+Y to the custom widget
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS+=(accept-autosuggestion-widget)

if [ ! -S ~/.ssh/ssh_auth_sock ] && [ -S "$SSH_AUTH_SOCK" ]; then
    ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. "$HOME/.cargo/env"

fpath+=~/.zfunc; autoload -Uz compinit; compinit
