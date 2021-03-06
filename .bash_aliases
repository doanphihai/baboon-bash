# Use custom prompt
source ~/.bash_prompt

HISTSIZE=500000
HISTFILESIZE=5000000

# set emacs mode for bash
set -o emacs

# Make emacs the default editor
export EDITOR='temacs -q'

# Aliases for emacs
alias e='emacsclient -n -a "" -F "((fullscreen . maximized))"'
alias em='e'
alias emc='e -c'
alias kill-emacs="emacsclient -e '(kill-emacs)'"

# Bashmarks (install from https://github.com/huyng/bashmarks)
source ~/.local/bin/bashmarks.sh

# General aliases
alias vlcncurses='vlc --intf ncurses'
alias youtube-dl-mp3='youtube-dl --extract-audio --audio-format mp3'
alias update-wallpaper='~/GitRepos/Muzei-Bash/checkMuzei.sh'
alias refresh-aliases='source ~/.bash_aliases'
alias refresh-bashrc='source ~/.bashrc'
alias sudo='sudo '
alias n='nano'
alias sn='sudo nano'
alias b='bundle exec'
alias si='sudo apt-get install'

# General functions
function pse {
    ps -e | grep "$@"
}
function psi {
    pse "$@" | awk '{print $1}'
}
function psk {
    kill -9 "$(psi "$@")"
}
function fullpath {
    readlink -f "$@"
}

source ~/GitRepos/baboon-singing/save-radios.sh

# Music
function fplay {
    find /mnt/trinasse/partage/Musique/ -type f -iname "*$@*" -print0 | xargs -0 vlc;
}
function fplayrand {
    find /mnt/trinasse/partage/Musique/ -type f -print0 -name '*.mp3' \
                                                     -o -name '*.flac' \
                                                     -o -name '*.mp4' \
        | shuf -zn "${1:-10}" \
        | xargs -0 ~/Downloads/deadbeef-devel/deadbeef;
}

# TMUX
if ! [[ -n $SSH_CLIENT ]]
then
    if which tmux >/dev/null 2>&1
    then
        # if no session is started, start a new session
        if test -z "${TMUX}"
        then
            read -p "Start tmux? (Y/n): "
            if ! [[ "$REPLY" = "n" ]]
            then
                (tmux new-window || tmux new-session -n 'jungle')

	        # when quitting tmux, try to attach
	        while test -z "${TMUX}"; do
        	    tmux attach || break
	        done
            fi
        fi
    fi
fi

# Docker
alias docker-rm-stopped-containers='docker rm $(docker ps -a -q)'
alias docker-rm-untagged-images='docker rmi $(docker images -a | grep '\''^<none>'\'' | awk '\''{print $3}'\'')'
alias docker-ps-short='docker ps -a | sed '\''s/\(  \+\)/\1?/g'\'' | cut -d"?" -f2,5,7 | tr -d "?"'

function docker-ip-for {
    docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$@"
}

# ranger
alias ranger='EDITOR=nano ranger'
alias watch-progesses='watch cv -q'
alias ssh-agent-start='eval `ssh-agent -s`'
alias mplayer-cmd='/home/louis/Scripts/mplayer-cmd.sh'

# touchpad (find the name with `xinput --list`)
function touchpad-enable {
    xinput enable "$TOUCHPAD_XINPUT_NAME"
}
function touchpad-disable {
    xinput disable "$TOUCHPAD_XINPUT_NAME"
}
alias blackbox='docker run -it --rm baboon:base /sbin/my_init -- bash'
alias myip='ip route get 8.8.8.8 | head -1 | cut -d'\'' '\'' -f8'

function github-repo-address-ssh {
    echo "git@github.com:"$1".git"
}
function github-repo-address-https {
    echo "https://github.com/"$1".git"
}
function github-clone-ssh {
    git clone "$(github-repo-address-ssh "$1")"
}
function github-clone-https {
    git clone "$(github-repo-address-https "$1")"
}
function openssl-test-server-and-port {
    # usage: openssl-test-server-and-port baboon.io:6999
    openssl s_client -showcerts -connect "$@"
}

alias suu='sudo apt-get update && sudo apt-get -y upgrade'

function find-big-files {
    find ${1-~} -type f -size +${2-50M} -exec ls -lh {} \;
}
alias tree-verbose='tree -DFlah '

function fix-ubuntu-date-widget {
    sudo apt-get install indicator-datetime
    sudo dpkg-reconfigure --frontend noninteractive tzdata
    sudo killall unity-panel-service
}
alias tmux-new-session='tmux new-session -t 0'

function move-window-leftmost {
    # move it
    wmctrl -r "$@" -e 0,0,0,-1,-1
    # put it in foreground
    wmctrl -a "$@"
}
function pa-list {
    pacmd list-sinks | awk '/index/ || /name:/'
}
function pa-set {
    # list all apps in playback tab (ex: cmus, mplayer, vlc)
    inputs=($(pacmd list-sink-inputs | awk '/index/ {print $2}'))
    # set the default output device
    pacmd set-default-sink $1 &> /dev/null
    # apply the changes to all running apps to use the new output device
    for i in ${inputs[*]}; do pacmd move-sink-input $i $1 &> /dev/null; done
}
function pa-playbacklist {
    # list individual apps
    echo "==============="
    echo "Running Apps"
    pacmd list-sink-inputs | awk '/index/ || /application.name /'

    # list all sound device
    echo "==============="
    echo "Sound Devices"
    pacmd list-sinks | awk '/index/ || /name:/'
}
function pa-playbackset {
    # set the default output device
    pacmd set-default-sink "$2" &> /dev/null
    # apply changes to one running app to use the new output device
    pacmd move-sink-input "$1" "$2" &> /dev/null
}
function calc {
    echo "puts $*" | ruby;
}
alias set-gaming-affinity='sudo su root -c "taskset -pc 0-6 $(pgrep dota2) && taskset -pc 7 $(pgrep vlc)"'

TRINASSE_IP=192.168.1.13
function mount-trinasse {
    local trinasse_share_name="$1"
    local trinasse_username="$2"
    local trinasse_password="$3"
    sudo mkdir -vp /mnt/trinasse/"${trinasse_share_name}"
    sudo mount.cifs \
         //"$TRINASSE_IP"/"${trinasse_share_name}" \
         /mnt/trinasse/"${trinasse_share_name}" \
         -o user="${trinasse_username}",pass="${trinasse_password}",uid=1000,gid=1000
}
alias df-disks-only='df -h | grep --color=never -e ^/'

alias opened-ports-localhost='sudo nmap -sV -O localhost'
alias ssh-frozen='echo "~.<cr>" | xclip -sel clip'
unalias ll
alias ll='ls -alFh'
alias ag-unique-ready='ag --nogroup --nobreak --noheading --nocolor --nofilename --nonumbers -w'

function xcopy {
    xclip -i "$1" -sel clip
}
