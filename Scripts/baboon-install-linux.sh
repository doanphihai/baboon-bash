#!/bin/bash

# stop script on error
set -eo pipefail

# Ask root password for sudo usage
echo "Please input root password"
read -s -p Password: pswd

SUDO="echo $pswd | sudo -S"

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
"$SUDO" <<EOF
  add-apt-repository -y ppa:mutate/ppa
  add-apt-repository -y ppa:pi-rho/dev
  add-apt-repository -y ppa:moka/stable
  add-apt-repository -y ppa:mozillateam/firefox-next
EOF

write-notice "Updating the system"
"$SUDO" <<EOF
  apt-get -y update
  apt-get -y upgrade
EOF

write-notice "Installing programs via apt-get"
"$SUDO" apt-get install -y \
     curl git-core gitg xclip jq tree caca-utils lynx poppler-utils \
     mediainfo wmctrl unity-tweak-tool compizconfig-settings-manager compiz-plugins \
     utfout libncurses5-dev libncursesw5-dev \
     moka-icon-theme faba-mono-icons \
     highlight atool mplayer \
     automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev \
     tmux mutate randomize-lines sbcl firefox ncdu nethogs redshift-gtk \
     aspell-fr kcolorchooser

# In mutate, use the shortcut Ctrl+Meta+S to launch (type it in)

write-notice "Setting Theme"
gsettings set org.gnome.desktop.interface icon-theme "Faba-mono" # <- not sure if that always works, can always use "Unity Tweak"

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

write-notice "Adding shortcuts (F2->F4 - F7->F8) for terminal/emacs/firefox/dota2/vlc"
media_keys=org.gnome.settings-daemon.plugins.media-keys
keymap=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/

# one per custom keybinding
gsettings set $media_keys custom-keybindings "['"$keymap"custom1/',
                                               '"$keymap"custom2/',
                                               '"$keymap"custom3/',
                                               '"$keymap"custom4/',
                                               '"$keymap"custom5/']"

gsettings set $media_keys.custom-keybinding:"$keymap"custom1/ name "switch-to-terminal"
gsettings set $media_keys.custom-keybinding:"$keymap"custom1/ command "/home/baboon/Scripts/cycle_window.sh terminal"
gsettings set $media_keys.custom-keybinding:"$keymap"custom1/ binding "F2"

gsettings set $media_keys.custom-keybinding:"$keymap"custom2/ name "switch-to-emacs"
gsettings set $media_keys.custom-keybinding:"$keymap"custom2/ command "bash /home/baboon/Scripts/cycle_window.sh emacs"
gsettings set $media_keys.custom-keybinding:"$keymap"custom2/ binding "F3"

gsettings set $media_keys.custom-keybinding:"$keymap"custom3/ name "switch-to-firefox"
gsettings set $media_keys.custom-keybinding:"$keymap"custom3/ command "bash /home/baboon/Scripts/cycle_window.sh firefox"
gsettings set $media_keys.custom-keybinding:"$keymap"custom3/ binding "F4"

gsettings set $media_keys.custom-keybinding:"$keymap"custom4/ name "switch-to-dota2"
gsettings set $media_keys.custom-keybinding:"$keymap"custom4/ command "wmctrl -xa dota2"
gsettings set $media_keys.custom-keybinding:"$keymap"custom4/ binding "F7"

gsettings set $media_keys.custom-keybinding:"$keymap"custom5/ name "switch-to-vlc"
gsettings set $media_keys.custom-keybinding:"$keymap"custom5/ command "bash /home/baboon/Scripts/cycle_window.sh vlc"
gsettings set $media_keys.custom-keybinding:"$keymap"custom5/ binding "F8"

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
"$SUDO" chmod +x set_dark.sh
./set_dark.sh

write-notice "Fixing default shortcuts"
# unbind SUPER key
dconf write /org/compiz/profiles/unity/plugins/unityshell/show-launcher '""'
# unbind ALT key
dconf write /org/compiz/integrated/show-hud '[""]'
# unbind ALT+Space key
dconf write /org/gnome/desktop/wm/keybindings/activate-window-menu '[""]'

write-notice "Installing bananamacs"
"$SUDO" apt-get build-dep emacs24
EMACS_VER=24.4
cd ~
mkdir Tools
cd Tools
wget http://ftp.gnu.org/gnu/emacs/emacs-"$EMACS_VER".tar.gz
tar -xf emacs-"$EMACS_VER".tar.gz
cp -r emacs-"$EMACS_VER" temacs-"$EMACS_VER"
# Make regular Emacs
cd emacs-"$EMACS_VER"
mkdir build
cd build
export CC=gcc CXX=g++; ../configure --prefix=/usr/local  --with-x-toolkit=gtk3 --with-wide-int && make bootstrap
"$SUDO" make install
# Mame Emacs for terminal use
cd ~/Tools/temacs-"$EMACS_VER"
./autogen.sh
mkdir build
cd build
export CC=gcc CXX=g++; ../configure --prefix=/usr/local --program-prefix=t --without-all --without-x --with-wide-int --with-xml2 && make bootstrap
"$SUDO" make install
# Set up .emacs.d
cd ~
mkdir -vp .emacs.d
cd .emacs.d
git-force-pull-repo git@github.com:LouisKottmann/baboon-emacs.git

write-notice "Installing AG - the silver searcher"
cd ~/tmp
git clone git@github.com:ggreer/the_silver_searcher.git
cd the_silver_searcher
"$SUDO" chmod +x build.sh
./build.sh
"$SUDO" make install

write-notice "Setting up Muzei"
cd ~/GitRepos/Muzei-Bash/
chmod +x checkMuzei.sh MuzeiBash.sh
# every day at 11am
{ crontab -l; echo "00 11 * * * $(whoami) /home/$(whoami)/GitRepos/Muzei-Bash/checkMuzei.sh"; } | crontab -

write-notice "Installing Quicklisp, SLIME & SBCL sources"
cd ~/tmp
curl -O http://beta.quicklisp.org/quicklisp.lisp
sbcl --non-interactive \
     --noprint \
     --load quicklisp.lisp \
     --eval '(quicklisp-quickstart:install)' \
     --eval '(ql:add-to-init-file)' \
     --eval '(ql:quickload "quicklisp-slime-helper")' \
     --eval '(ql:quickload "clhs")' \
     --eval '(clhs:install-clhs-use-local)'
"$SUDO" git clone https://github.com/sbcl/sbcl.git /opt/sbcl

write-notice "Installing bananamacs dependencies"
emacs --daemon
kill-emacs

write-notice "Installing shellcheck"
"$SUDO" apt-get -y install cabal-install
cabal update
cabal install cabal-install
cabal install shellcheck
echo "export PATH=$PATH:$HOME/.cabal/bin" >> "$HOME"/.bashrc

write-notice "Installing cv"
cd ~/GitRepos
git clone git@github.com:Xfennec/cv.git
cd cv
make
"$SUDO" make install

write-notice "Installing tldr" # Shortened man pages
cd ~/tmp
wget https://github.com/pranavraja/tldr/releases/download/v1/tldr_0.1.0_amd64.deb
"$SUDO" dpkg -i tldr_0.1.0_amd64.deb

write-notice "Installing fzf" # Fuzzy completion on C-t (current dir) C-r (history) and M-c (cd)
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

echo "https://krita.org/download/krita-desktop/" | xclip -sel clip
write-notice "Url to install Krita has been saved to clipboard"

write-notice "Removing warnings during GnuPG interaction with Gnome keyring"
"$SUDO" sed -i s/AGENT_ID/AGENX_ID/ "$(which gpg2)"

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
