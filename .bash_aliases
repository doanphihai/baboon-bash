# Custom prompt

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

    # basic information (user@host:path)
    PS1+="\[$BRed\]\u\[$Color_Off\]@\[$BRed\]\h\[$Color_Off\]:\[$BPurple\]\w\[$Color_Off\] "

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
        PS1+="\[$Color_On\][$branch]\[$Color_Off\] "
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
alias em-no-c='emacsclient -n -a "" -F "((fullscreen . maximized))"'
alias em='em-no-c || em-no-c -c'
alias kill-emacs="emacsclient -e '(kill-emacs)'"

# Radios
function radio {
    wget "$@" -O - | mplayer -cache-min 64 -cache 256 -
}
### ?ua=wwwradioclassique
CLASSIQUE=http://radioclassique.ice.infomaniak.ch/radioclassique-high.mp3
SIZE=http://size.ice.infomaniak.ch/size-128.mp3
MEUH=http://genisse.radiomeuh.com/big.mp3
alias radio-classique="radio $CLASSIQUE"
alias radio-size="radio $SIZE"
alias radio-meuh="radio $MEUH"

# Music
function fplay {
    find /media/trinasse/partage/Musique/ -type f -iname "*$@*" -print0 | xargs -0 vlc;
}

# Bashmarks (install from https://github.com/huyng/bashmarks)
source ~/.local/bin/bashmarks.sh

# General aliases
alias vlcncurses='vlc --intf ncurses'
alias youtube-dl-mp3='youtube-dl --extract-audio --audio-format mp3'
