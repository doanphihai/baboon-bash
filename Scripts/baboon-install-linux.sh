#!/bin/bash

# stop script on error
set -e

write-notice() {
    echo
    echo "**************************"
    echo "$1"
    echo "**************************"
    echo
}
git-force-pull-repo() {
    git init
    git remote add origin "$@"
    git fetch origin master
    git reset --hard FETCH_HEAD
    git branch --set-upstream-to=origin/master master
}
quicklisp-eval() {
    sbcl --load quicklisp.lisp --non-interactive --eval "$@"
}

write-notice "Adding ppas"
sudo add-apt-repository -y ppa:cassou/emacs
sudo add-apt-repository -y ppa:synapse-core/testing
sudo add-apt-repository -y ppa:ubuntu-mozilla-daily/firefox-aurora
sudo add-apt-repository -y ppa:kilian/f.lux
sudo add-apt-repository -y ppa:pi-rho/dev

write-notice "Updating the system"
sudo apt-get -y update
sudo apt-get -y upgrade

write-notice "Installing programs via apt-get"
sudo apt-get install -y \
     curl git-core gitg xclip \
     automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev \
     fluxgui tmux synapse \
     sbcl emacs-snapshot-el emacs-snapshot-gtk emacs-snapshot

write-notice "Now generating SSH key"
cd ~
ssh-keygen
xclip -sel clip < ~/.ssh/id_rsa.pub
echo "Your new public key has been copied to the clipboard, please go paste it in Github"
read -p "Ready to continue? (press ENTER)"

write-notice "Installing bashmarks"
cd ~
mkdir -vp ~/tmp
cd ~/tmp
git clone git://github.com/huyng/bashmarks.git
cd bashmarks
make install

write-notice "Fixing .bashrc"
sed -i 's/^alias l=.\+$//' .bashrc # removes alias l so that bashmarks can work properly
source ~/.bashrc

write-notice "Installing baboon-bash"
cd ~
git-force-pull-repo git@github.com:LouisKottmann/baboon-bash.git
source ~/.bash_aliases

write-notice "Configuring bash colors"
cd ~
eval `dircolors ~/.dircolors`
cd tmp
git clone https://github.com/sigurdga/gnome-terminal-colors-solarized.git
cd gnome-terminal-solarized
sudo chmod +x set_dark.sh
./set_dark.sh

write-notice "Fixing default shortcuts"
# unbind SUPER key
sudo dconf write /org/compiz/profiles/unity/plugins/unityshell/show-launcher '""'
# unbind ALT key
sudo dconf write /org/compiz/integrated/show-hud '[""]'

write-notice "Installing bananamacs"
cd ~
mkdir -vp .emacs.d
cd .emacs.d
git-force-pull-repo git@github.com:LouisKottmann/baboon-emacs.git

write-notice "Installing AG - the silver searcher"
cd ~/tmp
git clone git@github.com:ggreer/the_silver_searcher.git
cd the_silver_searcher
sudo chmod +x build.sh
./build.sh
sudo make install

write-notice "Installing Quicklisp + SLIME"
cd ~/tmp
curl -O http://beta.quicklisp.org/quicklisp.lisp
lisp-eval '(quicklisp-quickstart:install)'
lisp-eval '(ql:add-to-init-file)'
lisp-eval '(ql:quickload "quicklisp-slime-helper")'

write-notice "Installing bananamacs dependencies"
emacs --daemon
kill-emacs

cd ~
write-notice "BABOON LINUX IS READY!"
