#!/usr/bin/env bash

# exit if a command fails
set -e

# Parse command line arguments
INSTALL_PREFIX=""
NO_DEPS=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--install-dir)
      INSTALL_PREFIX="$2"
      shift 2
      ;;
    --no-deps)
      NO_DEPS=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [-i|--install-dir <path>] [--no-deps]"
      echo "  -i, --install-dir: Specify custom install location (default: system-wide)"
      echo "  --no-deps:         Skip apt dependency install (caller already installed them)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [-i|--install-dir <path>] [--no-deps]"
      exit 1
      ;;
  esac
done

# follow instructions on https://github.com/tmux/tmux/wiki/Installing

# check out the latest release branch after cd into repo: git checkout <latest stable branch name>

# kill the current tmux server
tmux kill-server 2>/dev/null || true

if [ "$NO_DEPS" != true ]; then
  # install build packages
  apt-get install libevent-dev ncurses-dev build-essential bison pkg-config -y

  # install configuration dependencies
  apt-get install autoconf automake -y

  # install run dependencies
  apt-get install libevent ncurses -y
fi

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
  make && sudo make install
fi
