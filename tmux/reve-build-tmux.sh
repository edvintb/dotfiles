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

# install build packages 
apt-get install libevent-dev ncurses-dev build-essential bison pkg-config -y

# install configuration dependencies
apt-get install autoconf automake -y

# install run dependencies
apt-get install libevent ncurses -y

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

# source .zshrc again to update $PATH and put tmux there
cd $HOME
source .zshrc
