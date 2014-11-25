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

cd ~

write-notice "Adding ppas"
sudo add-apt-repository -y ppa:synapse-core/testing
sudo add-apt-repository -y ppa:kilian/f.lux
sudo add-apt-repository -y ppa:pi-rho/dev
sudo add-apt-repository -y ppa:jon-severinsson/ffmpeg
sudo add-apt-repository -y ppa:moka/stable

write-notice "Updating the system"
sudo apt-get -y update
sudo apt-get -y upgrade

write-notice "Installing programs via apt-get"
sudo apt-get install -y \
     curl git-core gitg xclip jq tree caca-utils lynx poppler-utils
     mediainfo wmctrl \
     utfout libncurses5-dev libncursesw5-dev \
     moka-icon-theme faba-mono-icons \
     highlight atool ranger mplayer ffmpeg \
     automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev \
     fluxgui tmux synapse wmctrl randomize-lines \
     sbcl

write-notice "Swap to firefox developer edition"
sudo apt-get remove -y firefox
cd ~/tmp
FIREFOX_DEV_ED_VERSION="35.0a2"
FIREFOX_DEV_ED_FULLNAME="firefox-${FIREFOX_DEV_ED_VERSION}.en-US.linux-x86_64.tar.bz2"
FIREFOX_DEV_ED_URL="https://download-installer.cdn.mozilla.net/pub/firefox/nightly/latest-mozilla-aurora/${FIREFOX_DEV_ED_FULLNAME}.tar.bz2"
curl -LO "$FIREFOX_DEV_ED_URL"
aunpack "$FIREFOX_DEV_ED_FULLNAME"
sudo ln -s firefox/firefox /usr/bin/firefox
cd ~

write-notice "Setting Theme"
gsettings set org.gnome.desktop.interface icon-theme "Faba-mono" # <- not sure if that works, can always use "Unity Tweak"

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
cd ~
sed -i 's/^alias l=.\+$//' .bashrc # removes alias l so that bashmarks can work properly
source ~/.bashrc
unalias l

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
cd gnome-terminal-colors-solarized
sudo chmod +x set_dark.sh
./set_dark.sh

write-notice "Fixing default shortcuts"
# unbind SUPER key
dconf write /org/compiz/profiles/unity/plugins/unityshell/show-launcher '""'
# unbind ALT key
dconf write /org/compiz/integrated/show-hud '[""]'
# unbind ALT+Space key
dconf write /org/gnome/desktop/wm/keybindings/activate-window-menu '[""]'

write-notice "Installing bananamacs"
EMACS_VER=24.4
cd ~
mkdir Tools
cd Tools
wget http://ftp.gnu.org/gnu/emacs/emacs-"$EMACS_VER".tar.gz
mkdir emacs
tar -xf emacs-"$EMACS_VER".tar.gz
cp -r emacs-"$EMACS_VER" temacs-"$EMACS_VER"
# Make regular Emacs
cd emacs/emacs-"$EMACS_VER"
mkdir build
cd build
export CC=gcc CXX=g++; ../configure --prefix=/usr/local  --with-x-toolkit=gtk3 --with-wide-int && make bootstrap
sudo make install
# Mame Emacs for terminal use
cd ~/Tools/temacs-"$EMACS_VER"
./autogen.sh
mkdir build
cd build
export CC=gcc CXX=g++; ../configure --prefix=/usr/local --program-prefix=t --without-all --without-x --with-wide-int --with-xml2 && make bootstrap
sudo make install
# Set up .emacs.d
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

write-notice "Installing shellcheck"
sudo apt-get -y install cabal
cabal update
cabal install cabal-install
cabal install shellcheck
echo "export PATH=$PATH:$HOME/.cabal/bin" >> "$HOME"/.bashrc

write-notice "Installing cv"
cd ~/GitRepos
git clone git@github.com:Xfennec/cv.git
cd cv
make
sudo make install

echo "https://krita.org/download/krita-desktop/" | xclip -sel clip
write-notice "Url to install Krita has been saved to clipboard"

cd ~
write-notice "BABOON LINUX IS READY!"

#TODO:
# 1 - To be scripted:

##Move current window to next monitor:
### Open CCSM
### Enable "Put"
### Configure it:
###        - "Put To Previous Output: C-s-KP4"
###        - "Put To Next Output: C-s-KP6"
###        -  disable everything else
###        -  speed up the animation (10 seems fine)

# 2 - v2.0
### make write-notice ask before installing:
###        - wrap each install procedure in `function <name> { ... }'
###        - add parameter to write-notice with the function name
###        - dynamically call the function if it's ok to install

# Offer to install Krita
