
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/conda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
        . "/opt/conda/etc/profile.d/conda.sh"
    else
        export PATH="/opt/conda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. "$HOME/.local/bin/env"

# ========================================
# PATH Configuration (from .zshrc)
# ========================================
# Prioritize local binaries first (custom builds of tmux, nvim, etc.)
# Note: Order matters! Build PATH in priority order
# First add standard directories
export PATH=$PATH:$HOME/bin
export PATH=$PATH:$HOME/bin-personal
export PATH=$PATH:$HOME/bin-work

# Then prepend priority paths (in reverse order of priority)
export PATH=/opt/homebrew/opt/llvm/bin:$PATH  # homebrew llvm (for clang)
export PATH=$HOME/.local/bin:$PATH            # custom builds (highest priority)

# Add path to custom binaries -- apt in old ubuntu versions won't download updated versions
export PATH=$PATH:$HOME/fzf/bin
export PATH=$PATH:$HOME/delta/target/release

# Go binaries
export PATH="${PATH}:/Users/edvintb/go/bin"
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/mnt/home/go/bin

# set the tmux tmpdir environment variable
export TMUX_TMPDIR=/tmp
export TERM="xterm-256color"  # Or export TERM="xterm-kitty"

# Set the XDG_CONFIG_HOME env variable
# export XDG_CONFIG_HOME=$HOME/.config/nvim
# export XDG_CONFIG_HOME=""

export PIP_EXTRA_INDEX_URL="https://us-west1-python.pkg.dev/dev-infra-422317/reve-python-packages/simple"

# ========================================
# Aliases (from .zshrc)
# ========================================
# Enable alias expansion in non-interactive shells
shopt -s expand_aliases
alias t=tmux
alias n=nvim
alias p=python3
alias sw=swatch
alias tms=tmux-sessionizer
alias kssh="kitty +kitten ssh"
alias k='kubectl'
alias ktx='kubectx'
alias gs='bash ~/bin-personal/git_status'
alias glog='git log --graph --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%an%C(reset)%C(bold yellow)%d%C(reset) %C(dim white)- %s%C(reset)" --all'
alias prune-branches='git fetch --prune && git branch -vv | grep ": gone]" | awk "{print \$1}" | xargs -r git branch -D'
alias gd='git diff'
alias ga='git add'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias print-path="echo '$PATH' | tr ':' '\n'"

# ========================================
# Functions (from .zshrc)
# ========================================
# Change directory and list files
cl() {
  cd "$1"; ls
}

# Get the present working file (full path)
pwf() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

# Source secrets if available
BASHRC_SECRETS=~/.dotfiles/.bash_secrets
if [[ -f $BASHRC_SECRETS ]]; then
    source $BASHRC_SECRETS
fi

# Source private config if available
BASHRC_PRIVATE=~/.dotfiles/bashrc_private
if [[ -f $BASHRC_PRIVATE ]]; then
    source $BASHRC_PRIVATE
fi
