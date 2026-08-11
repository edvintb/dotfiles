#!/usr/bin/env bash

# Install Rust-based performance tools as specified in CLAUDE.md
# All binaries will be installed to $HOME/.local/bin
# Installs run in parallel for speed on multi-core machines.

set -e

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

echo "Installing Rust performance tools to $BIN_DIR (parallel)"
echo ""

# Check if cargo is available
if ! command -v cargo &> /dev/null; then
    echo "Error: cargo is not installed. Please install Rust first:"
    echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

# Build dependencies. tree-sitter-cli pulls in rquickjs-sys, whose bindgen build
# script needs libclang; without it the whole install dies with "Unable to find
# libclang" and neovim then fails to build treesitter parsers at runtime.
if command -v apt-get &> /dev/null; then
    if command -v sudo &> /dev/null && sudo -n true 2>/dev/null; then SUDO="sudo"; else SUDO=""; fi
    MISSING_DEPS=()
    ls /usr/lib/llvm-*/lib/libclang.so* &> /dev/null || MISSING_DEPS+=(libclang-dev)
    command -v cc &> /dev/null || MISSING_DEPS+=(build-essential)
    command -v pkg-config &> /dev/null || MISSING_DEPS+=(pkg-config)
    if [ "${#MISSING_DEPS[@]}" -gt 0 ]; then
        echo "Installing build deps: ${MISSING_DEPS[*]}"
        $SUDO apt-get update > /dev/null 2>&1 || true
        $SUDO apt-get install -y "${MISSING_DEPS[@]}" > /dev/null 2>&1 \
            || echo "⚠ apt-get install failed; some tools may not build"
    fi
fi

# cargo builds under TMPDIR by default. On VMs where /tmp is a small tmpfs, 14
# parallel builds fill it and every install dies with ENOSPC — so build on disk.
# Each tool gets its own target dir: cargo takes an exclusive lock per build
# directory, so a single shared one would serialize all 14 installs.
BUILD_ROOT="${BUILD_ROOT:-$HOME/.cache/cargo-target}"
mkdir -p "$BUILD_ROOT"

LOG_DIR="$HOME/.cache/rust-tools-logs"
rm -rf "$LOG_DIR"
mkdir -p "$LOG_DIR"

# Each install runs in a background subshell, so it cannot set a variable in the
# parent. Failures are recorded as marker files instead and counted after wait.
install_cargo_tool() {
    local package=$1
    local log="$LOG_DIR/$package.log"
    if CARGO_TARGET_DIR="$BUILD_ROOT/$package" cargo install "$package" --root "$HOME/.local" > "$log" 2>&1; then
        echo "✓ $package"
    else
        echo "✗ $package FAILED (see $log)"
        touch "$LOG_DIR/$package.failed"
    fi
}

# Launch all installs in parallel
# NOTE: tree-sitter-cli is deliberately NOT here. Building it from source needs
# libclang (bindgen), which isn't a dependency of this script, so it failed
# silently on hosts without it. nvim/nvim-deps.sh owns that install — it prefers
# the prebuilt binary and falls back to a cargo build with libclang in place.
TOOLS=(
    fd-find
    ripgrep
    bat
    sd
    xcp
    du-dust
    bottom
    procs
    xh
    tokei
    hyperfine
    zoxide
)

for tool in "${TOOLS[@]}"; do
    install_cargo_tool "$tool" &
done

# eza is installed from its release tarball, not cargo: it hard-pins
# palette "=0.7.5" (0.7.6 was broken for them, see eza PR #1207) and that
# version no longer compiles on current stable rustc.
(
    log="$LOG_DIR/eza.log"
    if [ -x "$BIN_DIR/eza" ]; then
        echo "✓ eza (cached)"
    elif {
        EZA_VERSION=$(curl -fsSL https://api.github.com/repos/eza-community/eza/releases/latest \
            | grep '"tag_name"' | cut -d '"' -f 4)
        [ -n "$EZA_VERSION" ] &&
        curl -fsSL "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" \
            | tar xz -C "$BIN_DIR" ./eza
    } > "$log" 2>&1; then
        echo "✓ eza (release binary)"
    else
        echo "✗ eza FAILED (see $log)"
        touch "$LOG_DIR/eza.failed"
    fi
) &

TOTAL=$(( ${#TOOLS[@]} + 1 ))   # cargo tools + eza release binary
echo "Waiting for $TOTAL parallel installs..."
wait

FAILED=$(find "$LOG_DIR" -name '*.failed' | wc -l | tr -d ' ')

echo ""
if [ "$FAILED" -eq 0 ]; then
    echo "================================================"
    echo "All $TOTAL tools installed successfully!"
    echo "================================================"
    rm -rf "$BUILD_ROOT"
else
    echo "================================================"
    echo "$FAILED of $TOTAL tools failed — logs in $LOG_DIR"
    echo "================================================"
    exit 1
fi
