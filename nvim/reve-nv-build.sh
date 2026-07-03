# steps taken from Build.MD inside the neovim repo: https://github.com/neovim/neovim/blob/master/BUILD.md

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

nvim_path=$HOME/neovim

# install build pre-reqs
if [ "$NO_DEPS" != true ]; then
  sudo apt-get install ninja-build gettext cmake curl build-essential -y
fi

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
  sudo make install
fi
