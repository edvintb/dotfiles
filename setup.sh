#!/usr/bin/env bash
# setup.sh — Full environment setup for local machines and VMs
# Installs oh-my-zsh, plugins, tools, and creates dotfiles symlinks
#
# Prerequisites:
#   - ~/.dotfiles must exist (this directory or a symlink to dotfiles repo)
#   - Git credentials must be set up (~/.netrc or ~/.git-credentials)

set -e

# Resolve the actual repo location (dir containing this script), so the
# ~/.dotfiles symlink points at the real checkout instead of at itself.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PREFIX="$HOME/.local"
LOCAL_BIN="$PREFIX/bin"

# Check if sudo is available and use it for apt-get
if command -v sudo &> /dev/null && sudo -n true 2>/dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi

# tmux/neovim are compiled from source via the standalone build scripts and are
# opt-in: only build them (and install the apt build deps they need) when the
# corresponding flag is passed.
BUILD_TMUX=false
BUILD_NVIM=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tmux) BUILD_TMUX=true; shift ;;
        --nvim) BUILD_NVIM=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--tmux] [--nvim]"
            echo "  --tmux   build tmux from source (tmux/build-tmux.sh)"
            echo "  --nvim   build neovim from source (nvim/nv-build.sh)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--tmux] [--nvim]"
            exit 1
            ;;
    esac
done

echo "============================================"
echo "  Development Environment Setup"
echo "  Installing to: $PREFIX"
echo "============================================"
echo ""

export PATH="$LOCAL_BIN:$HOME/.cargo/bin:$PATH"

# -----------------------------------------------
# Progress reporting helpers
# -----------------------------------------------
SECONDS=0                       # bash builtin: auto-incrementing elapsed seconds
log() { echo "[+${SECONDS}s] $*"; }

# Wait for a single background PID, printing a heartbeat every 10s so long
# steps don't look frozen. Returns the job's exit status.
wait_with_progress() {
    local pid="$1" label="$2"
    while kill -0 "$pid" 2>/dev/null; do
        sleep 10
        kill -0 "$pid" 2>/dev/null && log "… still waiting on ${label}"
    done
    wait "$pid"
}

# Wait for all remaining background jobs, with a heartbeat reporting how many
# are still running.
wait_all_with_progress() {
    local label="$1" n
    while [ -n "$(jobs -rp)" ]; do
        sleep 10
        n="$(jobs -rp | wc -l | tr -d ' ')"
        [ "$n" -gt 0 ] && log "… ${label}: ${n} job(s) still running"
    done
    wait
}

# -----------------------------------------------
# 1. Kick off independent background work immediately
# -----------------------------------------------
# These groups have no dependencies on each other:
#   - apt-get (only when --tmux/--nvim, needed by those builds later)
#   - rustup (needed by rust-tools-install later)
#   - binary downloads (fzf, delta, gh, claude, node) — fully independent
# Running them concurrently saves ~60-90s vs the previous serial layout.

log ">>> Starting parallel installs (rustup, binary downloads)..."

# NOTE: tmux/neovim build dependencies are NOT installed here — each build
# script (tmux/build-tmux.sh, nvim/nv-build.sh) installs its own apt
# deps, so this script doesn't need to know them. curl (for the downloads below)
# and zsh are assumed present on the base image.

# --- Rust toolchain (needed before rust-tools-install) ---
(
    if command -v cargo &> /dev/null && [ -f "$HOME/.cargo/env" ]; then
        echo "✓ rust (cached)"
    else
        if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path > /tmp/rustup-install.log 2>&1; then
            echo "✓ rust toolchain installed"
        else
            echo "✗ rust toolchain install FAILED (see /tmp/rustup-install.log)"
            exit 1
        fi
    fi
    "$HOME/.cargo/bin/rustup" default stable 2>/dev/null || true
) &
RUST_PID=$!

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

# --- Claude Code (native installer, standalone binary into ~/.local/bin) ---
(
    if [ -x "$LOCAL_BIN/claude" ]; then
        echo "✓ claude code (cached)"
    else
        curl -fsSL https://claude.ai/install.sh | bash > /dev/null 2>&1
        echo "✓ claude code installed"
    fi
) &

# --- oh-my-zsh + plugins (.zshrc loads zsh-syntax-highlighting, zsh-autosuggestions) ---
(
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "✓ oh-my-zsh (cached)"
    else
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            "" --unattended > /dev/null 2>&1
        echo "✓ oh-my-zsh installed"
    fi
    OMZ_CUSTOM="$HOME/.oh-my-zsh/custom/plugins"
    mkdir -p "$OMZ_CUSTOM"
    [ -d "$OMZ_CUSTOM/zsh-syntax-highlighting" ] || \
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$OMZ_CUSTOM/zsh-syntax-highlighting" > /dev/null 2>&1
    [ -d "$OMZ_CUSTOM/zsh-autosuggestions" ] || \
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
            "$OMZ_CUSTOM/zsh-autosuggestions" > /dev/null 2>&1
    echo "✓ zsh plugins (syntax-highlighting, autosuggestions)"
) &

# --- uv (Astral) — creates ~/.local/bin/env which .zshrc sources ---
(
    if [ -x "$LOCAL_BIN/uv" ] && [ -f "$LOCAL_BIN/env" ]; then
        echo "✓ uv (cached)"
    else
        curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$LOCAL_BIN" sh > /tmp/uv-install.log 2>&1
        # Fallback: if the installer didn't write env (some uv versions skip it),
        # generate a minimal one so .zshrc's `. "$HOME/.local/bin/env"` works.
        if [ ! -f "$LOCAL_BIN/env" ]; then
            cat > "$LOCAL_BIN/env" <<'ENVEOF'
#!/bin/sh
case ":${PATH}:" in
    *:"$HOME/.local/bin":*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
ENVEOF
        fi
        echo "✓ uv installed"
    fi
) &

# --- Node.js via nvm ---
(
    if [ -d "$HOME/.nvm/versions/node" ] && ls "$HOME/.nvm/versions/node/" &>/dev/null; then
        echo "✓ node (cached)"
    else
        if [ -f "$DOTFILES_DIR/ubuntu-install/node-install.sh" ]; then
            bash "$DOTFILES_DIR/ubuntu-install/node-install.sh" > /dev/null 2>&1
        fi
        echo "✓ node installed via nvm"
    fi
) &

# --- tree-sitter CLI (needed for neovim treesitter plugin) ---
(
    # Ensure Node is available first by sourcing nvm
    if [ -f "$HOME/.nvm/nvm.sh" ]; then
        # shellcheck disable=SC1091
        . "$HOME/.nvm/nvm.sh"
    fi
    # Check if tree-sitter is already installed globally
    if npm list -g tree-sitter-cli > /dev/null 2>&1; then
        echo "✓ tree-sitter (cached)"
    elif command -v npm &> /dev/null; then
        npm install -g tree-sitter-cli > /dev/null 2>&1
        echo "✓ tree-sitter CLI installed"
    else
        echo "! tree-sitter skipped (npm not available)"
    fi
) &

# -----------------------------------------------
# 2. Ensure base dirs / dotfiles self-symlink (needed by background installs)
# -----------------------------------------------
# Point ~/.dotfiles at the real checkout. Only create/repair the symlink when
# it doesn't already resolve to $DOTFILES_DIR — this also fixes a prior
# self-referential loop (~/.dotfiles -> ~/.dotfiles).
if [ "$DOTFILES_DIR" != "$HOME/.dotfiles" ]; then
    if [ ! -L "$HOME/.dotfiles" ] || [ "$(readlink "$HOME/.dotfiles")" != "$DOTFILES_DIR" ]; then
        rm -f "$HOME/.dotfiles"
        ln -sf "$DOTFILES_DIR" "$HOME/.dotfiles"
    fi
fi

mkdir -p "$HOME/.config"
mkdir -p "$LOCAL_BIN"

# -----------------------------------------------
# 3. Launch opt-in builds + rust tools
# -----------------------------------------------
# tmux/neovim are opt-in via --tmux/--nvim, and each build script installs its
# own apt dependencies (so the caller doesn't manage them). The heavy build
# logic lives in the standalone scripts so they can also be run by hand.
# rust-tools-install needs cargo from rustup.
echo ""
log ">>> Launching requested builds..."

if [ "$BUILD_TMUX" = true ]; then
    (
        if bash "$DOTFILES_DIR/tmux/build-tmux.sh" -i "$PREFIX" > /tmp/tmux-build.log 2>&1; then
            echo "✓ tmux built from source"
        else
            echo "✗ tmux build FAILED (see /tmp/tmux-build.log)"
        fi
    ) &
fi

if [ "$BUILD_NVIM" = true ]; then
    (
        if bash "$DOTFILES_DIR/nvim/nv-build.sh" -i "$PREFIX" > /tmp/nvim-build.log 2>&1; then
            echo "✓ neovim built from source"
        else
            echo "✗ neovim build FAILED (see /tmp/nvim-build.log)"
        fi
    ) &
fi

# Once rustup is done, kick off rust-tools-install (internally parallel).
wait_with_progress $RUST_PID "rust toolchain"
export PATH="$HOME/.cargo/bin:$PATH"
if [ -f "$DOTFILES_DIR/ubuntu-install/rust-tools-install.sh" ]; then
    bash "$DOTFILES_DIR/ubuntu-install/rust-tools-install.sh" &
fi

# Wait for everything (initial bg downloads + dependent builds + rust tools)
wait_all_with_progress "installs"
log "✓ All parallel installs complete"

# -----------------------------------------------
# 4. Symlink dotfiles (runs after all installs complete)
# -----------------------------------------------
echo ""
echo ">>> Setting up dotfiles symlinks..."

# symlink.sh is the single source of truth for every dotfile symlink: it backs
# up any pre-existing regular file to <file>.backup before linking, and skips
# sources that aren't present on this host.
bash "$DOTFILES_DIR/symlink.sh"

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

[ "$BUILD_TMUX" = true ] && check "tmux" "tmux"
[ "$BUILD_NVIM" = true ] && check "neovim" "nvim"
check "fzf" "fzf"
check "delta" "delta"
check "gh" "gh"
check "claude code" "claude"
check "uv" "uv"
check "zsh" "zsh"
[ -d "$HOME/.oh-my-zsh" ] && echo "  ✓ oh-my-zsh" || echo "  ✗ oh-my-zsh: NOT FOUND"
[ -f "$HOME/.cargo/env" ] && echo "  ✓ ~/.cargo/env" || echo "  ✗ ~/.cargo/env: NOT FOUND"
[ -f "$LOCAL_BIN/env" ] && echo "  ✓ ~/.local/bin/env" || echo "  ✗ ~/.local/bin/env: NOT FOUND"
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
echo "  Setup complete! (total ${SECONDS}s)"
echo "============================================"
echo ""
echo "Everything installed to $PREFIX."
echo "Source ~/.zshrc to get the full environment: exec zsh"
