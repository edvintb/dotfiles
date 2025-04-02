# follow instructions on https://github.com/tmux/tmux/wiki/Installing

# check out the latest release branch after cd into repo: git checkout <latest stable branch name>

# install build packages 
apt-get install libevent-dev ncurses-dev build-essential bison pkg-config

# install configuration dependencies
apt-get install autoconf automake

# install run dependencies
apt-get install libevent ncurses

# clone and install into $HOME
cd $HOME

# remove existing tmux directory
rm -rf tmux

git clone https://github.com/tmux/tmux.git
cd tmux
sh autogen.sh
./configure
make && sudo make install

# source .zshrc again to update $PATH and put tmux there
cd $HOME
source .zshrc
