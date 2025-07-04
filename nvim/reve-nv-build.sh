# steps taken from Build.MD inside the neovim repo: https://github.com/neovim/neovim/blob/master/BUILD.md

# exit if a command fails
set -e

nvim_path=$HOME/neovim

# install build pre-reqs
sudo apt-get install ninja-build gettext cmake curl build-essential -y

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
make CMAKE_BUILD_TYPE=RelWithDebInfo

# put binaries into the right places 
sudo make install
