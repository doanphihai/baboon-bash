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

write-notice "Adding ppas"
sudo add-apt-repository -y ppa:ubuntu-elisp/ppa
sudo add-apt-repository -y ppa:synapse-core/testing
sudo add-apt-repository -y ppa:ubuntu-mozilla-daily/firefox-aurora
sudo add-apt-repository -y ppa:kilian/f.lux
sudo add-apt-repository -y ppa:pi-rho/dev

write-notice "Updating the system"
sudo apt-get -y update
sudo apt-get -y upgrade

write-notice "Installing programs via apt-get"
sudo apt-get install -y \
     curl git-core gitg xclip jq tree caca-utils lynx poppler mediainfo \
     highlight atool ranger \
     automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev \
     fluxgui tmux synapse wmctrl randomize-lines \
     sbcl emacs-snapshot-el emacs-snapshot

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

write-notice "Adding shortcuts (F2->F4) for terminal/emacs/firefox"
media_keys=org.gnome.settings-daemon.plugins.media-keys
keymap=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/

# one per custom keybinding
gsettings set $media_keys custom-keybindings "['"$keymap"custom1/',
                                               '"$keymap"custom2/',
                                               '"$keymap"custom3/']"

gsettings set $media_keys.custom-keybinding:"$keymap"custom1/ name "switch-to-terminal"
gsettings set $media_keys.custom-keybinding:"$keymap"custom1/ command "wmctrl -xa terminal"
gsettings set $media_keys.custom-keybinding:"$keymap"custom1/ binding "F2"

gsettings set $media_keys.custom-keybinding:"$keymap"custom2/ name "switch-to-emacs"
gsettings set $media_keys.custom-keybinding:"$keymap"custom2/ command "wmctrl -xa emacs"
gsettings set $media_keys.custom-keybinding:"$keymap"custom2/ binding "F3"

gsettings set $media_keys.custom-keybinding:"$keymap"custom3/ name "switch-to-firefox"
gsettings set $media_keys.custom-keybinding:"$keymap"custom3/ command "wmctrl -xa firefox"
gsettings set $media_keys.custom-keybinding:"$keymap"custom3/ binding "F4"

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
dconf write /org/compiz/profiles/unity/plugins/unityshell/show-launcher '""'
# unbind ALT key
dconf write /org/compiz/integrated/show-hud '[""]'

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

write-notice "Setting up Muzei"
cd ~/GitRepos/Muzei-Bash/
chmod +x checkMuzei.sh MuzeiBash.sh
# every day at 11am
{ crontab -l; echo "00 11 * * * $(whoami) /home/$(whoami)/GitRepos/Muzei-Bash/checkMuzei.sh"; } | crontab -

write-notice "Installing Quicklisp + SLIME"
cd ~/tmp
curl -O http://beta.quicklisp.org/quicklisp.lisp
sbcl --non-interactive \
     --noprint \
     --load quicklisp.lisp \
     --eval '(quicklisp-quickstart:install)' \
     --eval '(ql:add-to-init-file)' \
     --eval '(ql:quickload "quicklisp-slime-helper")'

write-notice "Installing bananamacs dependencies"
emacs --daemon
kill-emacs

cd ~
write-notice "BABOON LINUX IS READY!"

# To be scripted:

##Move current window to next monitor:
### Open CCSM
### Enable "Put"
### Configure it:
###        - "Put To Previous Output: C-s-KP4"
###        - "Put To Next Output: C-s-KP6"
###        -  disable everything else
###        -  speed up the animation (10 seems fine)
