# steps taken from Build.MD inside the neovim repo: https://github.com/neovim/neovim/blob/master/BUILD.md

# exit if a command fails
set -e

# install build pre-reqs
sudo apt-get install ninja-build gettext cmake curl build-essential

# Clone the neovim repo -- script assumes this has already been done
# git clone https://github.com/neovim/neovim $HOME/neovim

# cd into the repo -- assumes cloned to $HOME
cd $HOME/neovim

# checkout the stable release
git checkout stable

# build binary using cmake
# make CMAKE_BUILD_TYPE=Release
# make CMAKE_BUILD_TYPE=Debug
make CMAKE_BUILD_TYPE=RelWithDebInfo

# put binaries into the right places 
sudo make install
