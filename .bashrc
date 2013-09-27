# Set emacs mode for bash
set -o emacs

# Make emacs the default editor
export EDITOR='emacsclient -c -a "" -F "((fullscreen . maximized))"'

# Aliases for emacs
alias em='emacsclient -c -n -a "" -F "((fullscreen . maximized))"'
alias kill-emacs="emacsclient -e '(kill-emacs)'"

