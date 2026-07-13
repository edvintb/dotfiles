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

# --- install Mason's runtime prerequisites ---
# Mason itself only installs *leaf* packages (ruff, pyright, lua_ls, ...) on top
# of runtimes that must already exist on PATH; it can't apt-install them itself
# because it runs unprivileged. Our mason-lspconfig ensure_installed includes
# `ruff`, which Mason installs into a Python venv via pip -- so python3 needs
# pip AND venv (stock Debian/Ubuntu python3 ships neither, which makes the
# `ruff` install fail on every nvim startup). unzip/wget/tar cover the generic
# download-and-extract path Mason uses for prebuilt binary packages.
$SUDO apt-get install -o DPkg::Lock::Timeout=300 -y \
  python3 python3-pip python3-venv unzip wget tar

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
