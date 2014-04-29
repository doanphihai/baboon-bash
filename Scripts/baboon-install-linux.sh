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
git-pull-repo() {
    git init
    rm .gitkeep
    git remote add origin $1
    git pull origin master
    git branch --set-upstream-to=origin/master master
}

write-notice "Adding ppas"
sudo add-apt-repository -y ppa:cassou/emacs
sudo add-apt-repository -y ppa:synapse-core/testing
sudo add-apt-repository -y ppa:ubuntu-mozilla-daily/firefox-aurora
sudo add-apt-repository -y ppa:kilian/f.lux
sudo add-apt-repository -y ppa:pi-rho/dev

write-notice "Updating the system"
sudo apt-get update
sudo apt-get upgrade

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

write-notice "Installing baboon-bash"
cd ~
git-pull-repo git@github.com:LouisKottmann/baboon-bash.git
source ~/.bash_aliases

write-notice "Fixing default shortcuts"
# unbind SUPER key
dconf write /org/compiz/profiles/unity/plugins/unityshell/show-launcher '""'
# unbind ALT key
dconf write /org/compiz/integrated/show-hud '[""]'

write-notice "Installing prelude"
cd ~
curl -L http://git.io/epre | sh
cd .emacs.d
cp sample/prelude-modules.el prelude-modules.el

write-notice "Installing baboon-emacs"
cd ~/.emacs.d/personal
rm -r preload/
git-pull-repo git@github.com:LouisKottmann/baboon-emacs.git

write-notice "Installing AG - the silver searcher"
cd ~/tmp
git clone git@github.com:ggreer/the_silver_searcher.git
cd the_silver_searcher
./build.sh
sudo make install

write-notice "Installing Quicklisp + SLIME"
cd ~/tmp
curl -O http://beta.quicklisp.org/quicklisp.lisp
sbcl --load quicklisp.lisp --non-interactive --eval '(quicklisp-quickstart:install)'
sbcl --load quicklisp.lisp --non-interactive --eval '(ql:add-to-init-file)'
sbcl --load quicklisp.lisp --non-interactive --eval '(ql:quickload "quicklisp-slime-helper")'

write-notice "Installing prelude dependencies"
emacs --daemon

write-notice "Installing baboon emacs dependencies"
emacsclient -e '(baboon-install-packages)'
kill-emacs

write-notice "Showing prelude modules files for modifications"
emc ~/.emacs.d/prelude-modules.el

write-notice "BABOON LINUX IS READY!"
