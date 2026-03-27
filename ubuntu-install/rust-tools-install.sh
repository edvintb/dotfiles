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

LOG_DIR=$(mktemp -d)
FAILED=0

install_cargo_tool() {
    local package=$1
    local log="$LOG_DIR/$package.log"
    if cargo install "$package" --root "$HOME/.local" > "$log" 2>&1; then
        echo "✓ $package"
    else
        echo "✗ $package FAILED (see $log)"
        FAILED=1
    fi
}

# Launch all installs in parallel
TOOLS=(
    fd-find
    ripgrep
    bat
    eza
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

echo "Waiting for ${#TOOLS[@]} parallel cargo installs..."
wait

echo ""
if [ "$FAILED" -eq 0 ]; then
    echo "================================================"
    echo "All ${#TOOLS[@]} tools installed successfully!"
    echo "================================================"
else
    echo "================================================"
    echo "Some tools failed — check logs in $LOG_DIR"
    echo "================================================"
fi
