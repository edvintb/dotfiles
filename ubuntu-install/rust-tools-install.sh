#!/usr/bin/env bash

# Install Rust-based performance tools as specified in CLAUDE.md
# All binaries will be installed to $HOME/.local/bin

set -e

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

echo "Installing Rust performance tools to $BIN_DIR"
echo "This may take a while as each tool needs to be compiled..."
echo ""

# Check if cargo is available
if ! command -v cargo &> /dev/null; then
    echo "Error: cargo is not installed. Please install Rust first:"
    echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

# Function to install a cargo package
install_cargo_tool() {
    local package=$1
    local binary=$2
    echo "Installing $package..."
    cargo install "$package" --root "$HOME/.local"
    echo "✓ $package installed"
    echo ""
}

# Core file/content search tools
install_cargo_tool "fd-find" "fd"
install_cargo_tool "ripgrep" "rg"

# File viewing and listing
install_cargo_tool "bat" "bat"
install_cargo_tool "eza" "eza"

# Text replacement
install_cargo_tool "sd" "sd"

# Disk usage
install_cargo_tool "du-dust" "dust"

# Process/system monitoring
install_cargo_tool "bottom" "btm"
install_cargo_tool "procs" "procs"

# HTTP client
install_cargo_tool "xh" "xh"

# Code statistics
install_cargo_tool "tokei" "tokei"

# Benchmarking
install_cargo_tool "hyperfine" "hyperfine"

# Smart directory navigation
install_cargo_tool "zoxide" "zoxide"

echo ""
echo "================================================"
echo "All tools installed successfully!"
echo "================================================"
echo ""
echo "Installed tools:"
echo "  fd       - Fast alternative to 'find'"
echo "  rg       - Fast alternative to 'grep'"
echo "  bat      - Cat with syntax highlighting"
echo "  eza      - Modern alternative to 'ls'"
echo "  sd       - Fast alternative to 'sed'"
echo "  dust     - Intuitive alternative to 'du'"
echo "  btm      - Bottom - process/system monitor"
echo "  procs    - Modern alternative to 'ps'"
echo "  xh       - Fast alternative to 'curl'"
echo "  tokei    - Count lines of code"
echo "  hyperfine - Command-line benchmarking tool"
echo "  zoxide   - Smarter cd command"
echo ""
echo "Note: zoxide requires additional setup in your shell config."
echo "Add this to your .zshrc or .bashrc:"
echo '  eval "$(zoxide init zsh)"  # for zsh'
echo '  eval "$(zoxide init bash)" # for bash'
