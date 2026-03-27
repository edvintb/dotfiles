#!/usr/bin/env bash
# pod-setup.sh — Full environment setup for GKR pods (megatron/brainatron/trainatron)
# Run this once on a new cluster to set up /mnt/home with all tools and configs.
# Usage: gkr s pod-setup -p 1 -g 0 -C m --cmd "bash /mnt/home/dotfiles/pod-setup.sh"
#
# Prerequisites:
#   - /mnt/home/dotfiles must be cloned (git clone https://github.com/edvintb/dotfiles.git /mnt/home/dotfiles)
#   - Git credentials must be set up (~/.netrc or ~/.git-credentials)

set -e

DOTFILES_DIR="/mnt/home/dotfiles"
LOCAL_BIN="$HOME/.local/bin"

echo "============================================"
echo "  GKR Pod Environment Setup"
echo "============================================"
echo ""

# -----------------------------------------------
# 1. System packages (zsh, tmux, neovim, build deps)
# -----------------------------------------------
echo ">>> Installing system packages..."
apt-get update -qq
apt-get install -y -qq \
    zsh \
    tmux \
    neovim \
    fzf \
    git-delta \
    curl \
    build-essential \
    cmake \
    ninja-build \
    gettext \
    autoconf \
    automake \
    bison \
    pkg-config \
    libevent-dev \
    ncurses-dev \
    > /dev/null 2>&1
echo "✓ System packages installed"

# -----------------------------------------------
# 2. Symlink dotfiles
# -----------------------------------------------
echo ""
echo ">>> Setting up dotfiles symlinks..."
# Ensure .dotfiles points to the cloned repo
if [ ! -L "$HOME/.dotfiles" ]; then
    ln -sf "$DOTFILES_DIR" "$HOME/.dotfiles"
fi

# Create .config directory (symlink.sh expects it to exist)
mkdir -p "$HOME/.config"

# Run symlink script with bash (it's written for zsh but works with bash for the link function)
cd "$DOTFILES_DIR"
# Manually run the symlink logic since symlink.sh uses zsh syntax
link() {
    local src="$1"
    local dst="$2"
    if [ -L "$dst" ]; then
        local current_target=$(readlink "$dst")
        if [ "$current_target" = "$src" ]; then
            echo "✓ Already linked: $dst"
            return 0
        else
            rm "$dst"
        fi
    elif [ -e "$dst" ]; then
        echo "⚠ Skipping (exists): $dst"
        return 1
    fi
    # Ensure parent directory exists
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "✓ Linked: $dst -> $src"
}

link "$HOME/.dotfiles/.bashrc" "$HOME/.bashrc"
link "$HOME/.dotfiles/.gitconfig" "$HOME/.gitconfig"
link "$HOME/.dotfiles/vimrc" "$HOME/.vimrc"

mkdir -p "$HOME/.claude"
link "$HOME/.dotfiles/claude/settings.json" "$HOME/.claude/settings.json"
link "$HOME/.dotfiles/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

link "$HOME/.dotfiles/nvim" "$HOME/.config/nvim"
link "$HOME/.dotfiles/tmux" "$HOME/.config/tmux"
link "$HOME/.dotfiles/lazygit" "$HOME/.config/lazygit"
link "$HOME/.dotfiles/lf" "$HOME/.config/lf"
link "$HOME/.dotfiles/bin" "$HOME/bin-personal"
link "$HOME/.dotfiles/tmux/tmux.conf" "$HOME/.tmux.conf"
echo "✓ Dotfiles linked"

# -----------------------------------------------
# 3. Install Rust and Rust-based CLI tools
# -----------------------------------------------
echo ""
echo ">>> Installing Rust toolchain..."
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    export PATH="$HOME/.cargo/bin:$PATH"
fi
echo "✓ Rust installed"

echo ""
echo ">>> Installing Rust CLI tools (this takes a while)..."
mkdir -p "$LOCAL_BIN"
bash "$DOTFILES_DIR/ubuntu-install/rust-tools-install.sh"
echo "✓ Rust tools installed"

# -----------------------------------------------
# 4. Install Node.js via nvm
# -----------------------------------------------
echo ""
echo ">>> Installing Node.js via nvm..."
bash "$DOTFILES_DIR/ubuntu-install/node-install.sh"
echo "✓ Node.js installed"

# -----------------------------------------------
# 5. Install GitHub CLI (gh)
# -----------------------------------------------
echo ""
echo ">>> Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt-get update -qq && apt-get install -y -qq gh > /dev/null 2>&1
fi
echo "✓ GitHub CLI installed"

# -----------------------------------------------
# 6. SSH setup (known_hosts for github)
# -----------------------------------------------
echo ""
echo ">>> Setting up SSH known_hosts..."
mkdir -p "$HOME/.ssh"
ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
echo "✓ SSH known_hosts configured"

# -----------------------------------------------
# 7. Verify installation
# -----------------------------------------------
echo ""
echo "============================================"
echo "  Verification"
echo "============================================"
echo ""

check() {
    local name="$1"
    local cmd="$2"
    if command -v "$cmd" &> /dev/null; then
        echo "✓ $name: $(command -v $cmd)"
    else
        echo "✗ $name: NOT FOUND"
    fi
}

check "zsh" "zsh"
check "tmux" "tmux"
check "neovim" "nvim"
check "fzf" "fzf"
check "gh" "gh"
check "cargo" "cargo"
check "fd" "fd"
check "ripgrep" "rg"
check "bat" "bat"
check "eza" "eza"
check "sd" "sd"
check "dust" "dust"
check "zoxide" "zoxide"
check "hyperfine" "hyperfine"
check "tokei" "tokei"

echo ""
echo "============================================"
echo "  Setup complete!"
echo "============================================"
echo ""
echo "Tools are installed to $LOCAL_BIN and /usr/bin."
echo "Source ~/.bashrc to get the full environment."
