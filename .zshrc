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
# this is where uv is installed
export PATH=$PATH:/mnt/home/.local/bin
export PATH=$PATH:/Applications/kitty.app/Contents/MacOS
export PATH=/opt/homebrew/opt/llvm/bin:$PATH  # want to use this version of clang first

# Add path to custom binaries -- apt in old ubuntu versions won't download updated versions
# export PATH=$PATH:$HOME/neovim/build/bin
export PATH=$PATH:$HOME/fzf/bin
export PATH=$PATH:$HOME/delta/target/release

# set the tmux tmpdir environment variable
export TMUX_TMPDIR=/tmp
export TERM="xterm-256color"  # Or export TERM="xterm-kitty"

# source secrets
ZSHRC_SECRETS=~/.dotfiles/.zsh_secrets
if [[ -f $ZSHRC_PRIVATE ]]; then
    source $ZSHRC_PRIVATE
fi

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
  cd "$1"; ls
}

# alias for printing PATH in a readable way
alias print-path="echo '$PATH' | tr ':' '\n'"

# get the present working file
pwf() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

uvl () {
# 1. Extract the current directory name (no parent path)
# Example: If PWD is /home/user/project_name, this extracts 'project_name'.
local cur_dir=$(basename "$PWD")

# 2. Define the absolute path for the virtual environment
# e.g., /tmp/project_name/.venv
# local venv_path="/tmp/${cur_dir}/.venv"
#
# # 3. Create the parent directory for the VENV if it doesn't exist.
# # We suppress errors (2>/dev/null) in case the directory already exists.
# mkdir -p "${venv_path}" 2>/dev/null
#
#
# # 4. Execute the uv command with the calculated UV_PROJECT_ENVIRONMENT
# # "$@" passes all arguments (sync, run, add, etc.) to the uv command.
# UV_PROJECT_ENVIRONMENT="${venv_path}" uv --preview-features extra-build-dependencies "$@"

# 2. Define the absolute paths for the VENV and the CACHE
local venv_path="/tmp/${cur_dir}/.venv"
local cache_path="/tmp/.uv-cache"

echo -e "Using venv: \033[34m${venv_path}\033[0m and cache: \033[34m${cache_path}\033[0m"

# 3. Create the necessary directories if they don't exist.
mkdir -p "${venv_path}" "${cache_path}" 2>/dev/null

# 4. Execute the uv command with calculated environment variables.
#
# We use a subshell (parentheses) to:
# a) unset VIRTUAL_ENV to suppress the mismatch warning.
# b) set UV_PROJECT_ENVIRONMENT (venv location).
# c) set UV_CACHE_DIR (cache location in /tmp).
# d) set UV_LINK_MODE=copy (to suppress the hardlink failure warning).
(
    unset VIRTUAL_ENV
    UV_PROJECT_ENVIRONMENT="${venv_path}" \
    UV_CACHE_DIR="${cache_path}" \
    uv --preview-features extra-build-dependencies "$@"
)

}

# reve aliases
alias qu-install="pip install -e /mnt/home/queryfile-util"

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

# this is where the go binary lives
export PATH="${PATH}:/Users/edvintb/go/bin"
export PATH=$PATH:/usr/local/go/bin

# this is where go places binaries
export PATH=$PATH:/mnt/home/go/bin

. "$HOME/.local/bin/env"
