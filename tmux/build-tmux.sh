#!/usr/bin/env bash

# exit if a command fails
set -e

# Parse command line arguments
INSTALL_PREFIX=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--install-dir)
      INSTALL_PREFIX="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [-i|--install-dir <path>]"
      echo "  -i, --install-dir: Specify custom install location (default: system-wide)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [-i|--install-dir <path>]"
      exit 1
      ;;
  esac
done

# follow instructions on https://github.com/tmux/tmux/wiki/Installing

# check out the latest release branch after cd into repo: git checkout <latest stable branch name>

# kill the current tmux server
tmux kill-server 2>/dev/null || true

# --- install build dependencies (self-contained: caller need not know them) ---
# Detect sudo: use it when we're not root and it's available.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  fi
fi

# -o DPkg::Lock::Timeout waits for the dpkg lock instead of failing outright,
# so a concurrent apt run (e.g. the nvim build) can coexist safely.
$SUDO apt-get update -o DPkg::Lock::Timeout=300 -qq
$SUDO apt-get install -o DPkg::Lock::Timeout=300 -y \
  libevent-dev ncurses-dev build-essential bison pkg-config autoconf automake

# clone and install into $HOME
cd $HOME

# remove existing tmux directory
rm -rf tmux

git clone https://github.com/tmux/tmux.git
cd tmux
sh autogen.sh

# configure with custom prefix if specified
if [ -n "$INSTALL_PREFIX" ]; then
  ./configure --prefix="$INSTALL_PREFIX"
else
  ./configure
fi

# build and install
if [ -n "$INSTALL_PREFIX" ]; then
  make && make install
else
  make && $SUDO make install
fi
