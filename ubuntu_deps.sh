# tmux library dependencies
# sudo apt install libevent-dev ncurses-dev build-essential bison pkg-config

# download tmux from github
# wget https://github.com/tmux/tmux/releases/download/3.5/tmux-3.5.tar.gz  # Replace 3.4 with the latest version
# tar -zxf tmux-3.5.tar.gz
# rm tmux-3.5.tar.gz
# cd tmux-3.5

# a recent node version is required to run lsp's in neovim
sudo apt update
sudo apt install curl gnupg2 lsb-release

curl -fsSL https://deb.nodesource.com/setup_23.x | sudo -E bash -  # Replace 18.x with the desired Node.js version (e.g., 20.x, 16.x)

sudo apt-get install nodejs

node -v
npm -v
