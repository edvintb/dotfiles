#!/usr/bin/env bash
# pod-setup.sh — Full environment setup for local machines and VMs
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
# These three groups have no dependencies on each other:
#   - apt-get (needed by tmux/nvim builds later)
#   - rustup (needed by rust-tools-install later)
#   - binary downloads (fzf, delta, gh, claude, node) — fully independent
# Running them concurrently saves ~60-90s vs the previous serial layout.

log ">>> Starting parallel installs (apt, rustup, binary downloads)..."

# --- apt build dependencies (ephemeral, needed for tmux/nvim from source) ---
# Skip entirely when tmux + nvim are already built, since apt is only needed to
# compile them from source — this turns cached re-runs from ~minute to instant.
(
    if [ -x "$LOCAL_BIN/tmux" ] && [ -x "$LOCAL_BIN/nvim" ]; then
        echo "✓ apt build deps (skipped — tmux/nvim cached)"
    else
        $SUDO apt-get update -qq
        $SUDO apt-get install -y -qq \
            curl \
            zsh \
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
        echo "✓ apt build dependencies installed"
    fi
) &
APT_PID=$!

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
# 3. Launch dependent builds as soon as their prerequisites finish
# -----------------------------------------------
# tmux + neovim need apt (build-essential, cmake, ninja, etc.)
# rust-tools-install needs cargo from rustup
# `wait $PID` only works on direct children of the current shell, so we
# block in the main shell rather than nested subshells. The other parallel
# downloads keep running concurrently while we wait here.
echo ""
log ">>> Waiting on prerequisites to launch dependent builds..."

# Once apt is done, fan out tmux + nvim builds in the background.
wait_with_progress $APT_PID "apt build dependencies"

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

link "$HOME/.dotfiles/init.sh" "$HOME/.dotfiles_rc"
link "$HOME/.dotfiles/.zshrc" "$HOME/.zshrc"
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
