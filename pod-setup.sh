#!/usr/bin/env bash
# pod-setup.sh — Full environment setup for GKR pods (megatron/brainatron/trainatron)
# Run this once on a new cluster to set up /mnt/home with all tools and configs.
# Usage: gkr s pod-setup -p 1 -g 0 -C m --cmd "bash /mnt/home/dotfiles/pod-setup.sh"
#
# Everything installs to /mnt/home/.local so it persists across pods.
# Only build dependencies (apt) are ephemeral and needed per-pod.
#
# Prerequisites:
#   - /mnt/home/dotfiles must be cloned (git clone https://github.com/edvintb/dotfiles.git /mnt/home/dotfiles)
#   - Git credentials must be set up (~/.netrc or ~/.git-credentials)

set -e

DOTFILES_DIR="/mnt/home/dotfiles"
PREFIX="$HOME/.local"
LOCAL_BIN="$PREFIX/bin"

echo "============================================"
echo "  GKR Pod Environment Setup"
echo "  Installing to: $PREFIX"
echo "============================================"
echo ""

export PATH="$LOCAL_BIN:$HOME/.cargo/bin:$PATH"

# -----------------------------------------------
# 1. Build dependencies (ephemeral, needed for compilation)
# -----------------------------------------------
echo ">>> Installing build dependencies..."
apt-get update -qq
apt-get install -y -qq \
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
echo "✓ Build dependencies installed"

# -----------------------------------------------
# 2. Symlink dotfiles
# -----------------------------------------------
echo ""
echo ">>> Setting up dotfiles symlinks..."
if [ ! -L "$HOME/.dotfiles" ]; then
    ln -sf "$DOTFILES_DIR" "$HOME/.dotfiles"
fi

mkdir -p "$HOME/.config"
mkdir -p "$LOCAL_BIN"

link() {
    local src="$1"
    local dst="$2"
    if [ -L "$dst" ]; then
        local current_target=$(readlink "$dst")
        if [ "$current_target" = "$src" ]; then
            return 0
        else
            rm "$dst"
        fi
    elif [ -e "$dst" ]; then
        echo "⚠ Skipping (exists): $dst"
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "✓ Linked: $dst"
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
# 3. Install Rust toolchain (needed before parallel Rust tools)
# -----------------------------------------------
echo ""
if command -v cargo &> /dev/null; then
    echo ">>> Rust already installed, skipping rustup"
else
    echo ">>> Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    export PATH="$HOME/.cargo/bin:$PATH"
fi
rustup default stable 2>/dev/null || true
echo "✓ Rust installed"

# -----------------------------------------------
# 4. Parallel installs: builds, downloads, and cargo tools all at once
# -----------------------------------------------
echo ""
echo ">>> Launching parallel installs (tmux, nvim, fzf, delta, gh, node, 13 rust tools)..."

# --- tmux from source ---
(
    if [ -x "$LOCAL_BIN/tmux" ]; then
        echo "✓ tmux (cached)"
    else
        cd /tmp && rm -rf tmux-build
        git clone --depth 1 https://github.com/tmux/tmux.git tmux-build 2>/dev/null
        cd tmux-build && sh autogen.sh > /dev/null 2>&1
        ./configure --prefix="$PREFIX" > /dev/null 2>&1
        make -j$(nproc) > /dev/null 2>&1 && make install > /dev/null 2>&1
        rm -rf /tmp/tmux-build
        echo "✓ tmux built from source"
    fi
) &

# --- neovim from source ---
(
    if [ -x "$LOCAL_BIN/nvim" ]; then
        echo "✓ neovim (cached)"
    else
        cd /tmp && rm -rf neovim-build
        git clone --depth 1 --branch stable https://github.com/neovim/neovim.git neovim-build 2>/dev/null
        cd neovim-build
        make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$PREFIX" -j$(nproc) > /dev/null 2>&1
        make install > /dev/null 2>&1
        rm -rf /tmp/neovim-build
        echo "✓ neovim built from source"
    fi
) &

# --- fzf binary ---
(
    if [ -x "$LOCAL_BIN/fzf" ]; then
        echo "✓ fzf (cached)"
    else
        FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')
        curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz" | tar xz -C "$LOCAL_BIN"
        echo "✓ fzf downloaded"
    fi
) &

# --- delta binary ---
(
    if [ -x "$LOCAL_BIN/delta" ]; then
        echo "✓ delta (cached)"
    else
        DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp
        cp "/tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu/delta" "$LOCAL_BIN/"
        rm -rf "/tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu"
        echo "✓ delta downloaded"
    fi
) &

# --- gh binary ---
(
    if [ -x "$LOCAL_BIN/gh" ]; then
        echo "✓ gh (cached)"
    else
        GH_VERSION=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')
        curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" | tar xz -C /tmp
        cp "/tmp/gh_${GH_VERSION}_linux_amd64/bin/gh" "$LOCAL_BIN/"
        rm -rf "/tmp/gh_${GH_VERSION}_linux_amd64"
        echo "✓ gh downloaded"
    fi
) &

# --- Node.js via nvm ---
(
    if [ -d "$HOME/.nvm/versions/node" ] && ls "$HOME/.nvm/versions/node/" &>/dev/null; then
        echo "✓ node (cached)"
    else
        bash "$DOTFILES_DIR/ubuntu-install/node-install.sh" > /dev/null 2>&1
        echo "✓ node installed via nvm"
    fi
) &

# --- All 13 Rust CLI tools (internally parallel too) ---
bash "$DOTFILES_DIR/ubuntu-install/rust-tools-install.sh" &

# Wait for everything
wait
echo "✓ All parallel installs complete"

# -----------------------------------------------
# 10. SSH setup (known_hosts for github)
# -----------------------------------------------
echo ""
echo ">>> Setting up SSH known_hosts..."
mkdir -p "$HOME/.ssh"
if ! grep -q "github.com" "$HOME/.ssh/known_hosts" 2>/dev/null; then
    ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
fi
echo "✓ SSH known_hosts configured"

# -----------------------------------------------
# 11. Verify installation
# -----------------------------------------------
echo ""
echo "============================================"
echo "  Verification"
echo "============================================"

check() {
    local name="$1"
    local cmd="$2"
    if command -v "$cmd" &> /dev/null; then
        echo "  ✓ $name"
    else
        echo "  ✗ $name: NOT FOUND"
    fi
}

check "tmux" "tmux"
check "neovim" "nvim"
check "fzf" "fzf"
check "delta" "delta"
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
echo "Everything installed to $PREFIX (persists on /mnt/home)."
echo "Source ~/.bashrc to get the full environment."
