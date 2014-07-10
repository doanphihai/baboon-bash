# Custom prompt

# Set to 1 to see user@host
FULL_PROMPT=0

##-ANSI-COLOR-CODES-##
Color_Off="\033[0m"
###-Regular-###
Red="\033[0;31m"
Green="\033[0;32m"
Purple="\033[0;35m"
####-Bold-####
BRed="\033[1;31m"
BPurple="\033[1;35m"
# set up command prompt
function ahead_behind {
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo ''
        return
    fi

    if ( ! git config --list | grep -E ^branch."$branch" > /dev/null )
    then
        echo ''
        return
    fi
    local remote=$(git config branch."$branch".remote)
    local merge_branch=$(git config branch."$branch".merge | cut -d / -f 3,4,5,6)
    local rev_list=$(git rev-list --left-right --count "$branch"..."$remote"/"$merge_branch")
    local behind=$(echo "$rev_list" | awk '{print $2}')
    if [[ "$1" == "--behind" ]]; then echo "$behind" && return; fi
    local ahead=$(echo "$rev_list" | awk '{print $1}')
    if [[ "$1" == "--ahead" ]]; then echo "$ahead" && return; fi
    local ahead_behind=""
    if [[ "$ahead" == 0 && "$behind" == 0 ]]; then
        echo ''
        return
    fi

    if [[ "$behind" == 0 ]]; then
        ahead_behind+="[$behind"
    else
        ahead_behind+="[\[$Red\]$behind\[$Color_Off\]"
    fi
    ahead_behind+="|"
    if [[ "$ahead" == 0 ]]; then
        ahead_behind+="$ahead]"
    else
        ahead_behind+="\[$Green\]$ahead\[$Color_Off\]]"
    fi
    echo "$ahead_behind"
}
function __prompt_command()
{
    # capture the exit status of the last command
    EXIT="$?"
    PS1=""

    if [ $EXIT -eq 0 ]; then PS1+="\[$Green\][\!]\[$Color_Off\] "; else PS1+="\[$Red\][\!]\[$Color_Off\] "; fi

    # if logged in via ssh shows the ip of the client
    if [ -n "$SSH_CLIENT" ]; then PS1+="\[$Yellow\]("${$SSH_CLIENT%% *}")\[$Color_Off\]"; fi

    # debian chroot stuff (take it or leave it)
    PS1+="${debian_chroot:+($debian_chroot)}"

    if [ $FULL_PROMPT -eq 1 ]; then
        PS1+="\[$BRed\]\u\[$Color_Off\]@\[$BRed\]\h\[$Color_Off\]:"
    fi

    # basic information (user@host:path)
    PS1+="\[$BPurple\]\w\[$Color_Off\] "

    # check if inside git repo
    local git_status="`git status -unormal 2>&1`"
    if ! [[ "$git_status" =~ Not\ a\ git\ repo ]]; then
        # parse the porcelain output of git status
        if [[ "$git_status" =~ nothing\ to\ commit ]]; then
            local Color_On=$Green
        elif [[ "$git_status" =~ nothing\ added\ to\ commit\ but\ untracked\ files\ present ]]; then
            local Color_On=$Purple
        else
            local Color_On=$Red
        fi

        if [[ "$git_status" =~ On\ branch\ ([^[:space:]]+) ]]; then
            branch=${BASH_REMATCH[1]}
        else
            # Detached HEAD. (branch=HEAD is a faster alternative.)
            branch="(`git describe --all --contains --abbrev=4 HEAD 2> /dev/null || echo HEAD`)"
        fi

        # add the result to prompt
        PS1+="\[$Color_On\][$branch]\[$Color_Off\]$(ahead_behind) "
    fi

    # prompt $ or # for root
    PS1+="\$ "
}

PROMPT_COMMAND=__prompt_command

# set emacs mode for bash
set -o emacs

# Make emacs the default editor
export EDITOR='emacsclient -c -a "" -F "((fullscreen . maximized))"'

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

# Radios
function radio {
    wget "$@" -O - | mplayer -cache-min 64 -cache 256 -
}
### ?ua=wwwradioclassique
CLASSIQUE=http://radioclassique.ice.infomaniak.ch/radioclassique-high.mp3
SIZE=http://size.ice.infomaniak.ch/size-128.mp3
MEUH=http://genisse.radiomeuh.com/big.mp3
NOVA=http://novazz.ice.infomaniak.ch/novazz-128.mp3
FIP=http://mp3lg.tdf-cdn.com/fip/all/fiphautdebit.mp3
alias radios='vlcncurses $SIZE $CLASSIQUE $MEUH $NOVA $FIP'

source ~/GitRepos/baboon-singing/save-radios.sh

# Music
function fplay {
    find /media/trinasse/partage/Musique/ -type f -iname "*$@*" -print0 | xargs -0 vlc;
}

# TMUX
if which tmux 2>&1 >/dev/null; then
    # if no session is started, start a new session
    test -z ${TMUX} && (tmux new-window || tmux new-session -n 'jungle')

    # when quitting tmux, try to attach
    while test -z ${TMUX}; do
        tmux attach || break
    done
fi

# Docker
alias docker-rm-stopped-containers='docker rm $(docker ps -a -q)'
alias docker-rm-untagged-images='docker rmi $(docker images -a | grep '\''^<none>'\'' | awk '\''{print $3}'\'')'

function docker-ip-for {
    docker inspect "$@" | grep IPAddress | cut -d'"' -f4
}

# ranger
alias ranger='EDITOR=nano ranger'
