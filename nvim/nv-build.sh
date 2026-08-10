# steps taken from Build.MD inside the neovim repo: https://github.com/neovim/neovim/blob/master/BUILD.md

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

nvim_path=$HOME/neovim

# --- install build pre-reqs (self-contained: caller need not know them) ---
# Detect sudo: use it when we're not root and it's available.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  fi
fi

# -o DPkg::Lock::Timeout waits for the dpkg lock instead of failing outright,
# so a concurrent apt run (e.g. the tmux build) can coexist safely.
$SUDO apt-get update -o DPkg::Lock::Timeout=300 -qq
$SUDO apt-get install -o DPkg::Lock::Timeout=300 -y \
  ninja-build gettext cmake curl build-essential

# NOTE: this script installs only what's needed to *build the binary*. The
# dependencies the config's plugins need at runtime -- the tree-sitter CLI,
# Mason's python/node runtimes, ImageMagick, a JDK, ... -- live in
# nvim/nvim-deps.sh, which also does the headless lazy/parser/mason bootstrap.
# Run it after this script (setup.sh --nvim does both in order).

# remove repo (if exists) and clone the latest version
rm -rf $nvim_path
git clone https://github.com/neovim/neovim $nvim_path

# cd into the repo
cd $nvim_path

# checkout the stable release -- no need to use anything unstable
git checkout stable

# build binary using cmake
# make CMAKE_BUILD_TYPE=Release
# make CMAKE_BUILD_TYPE=Debug
if [ -n "$INSTALL_PREFIX" ]; then
  make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
else
  make CMAKE_BUILD_TYPE=RelWithDebInfo
fi

# put binaries into the right places
if [ -n "$INSTALL_PREFIX" ]; then
  make install
else
  $SUDO make install
fi
