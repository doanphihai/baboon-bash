#!/bin/bash

GIT_BEST_SONGS_REPO=$HOME/GitRepos/baboon-singing
KNOWN_RADIOS=('classique' 'size' 'nova' 'fip')

# Radios
function radio {
    wget "$@" -O - | mplayer -cache-min 64 -cache 256 -
}
### Urls
CLASSIQUE=http://radioclassique.ice.infomaniak.ch/radioclassique-high.mp3
SIZE=http://size.ice.infomaniak.ch/size-128.mp3
MEUH=http://genisse.radiomeuh.com/big.mp3
NOVA=http://novazz.ice.infomaniak.ch/novazz-128.mp3
FIP=http://mp3lg.tdf-cdn.com/fip/all/fiphautdebit.mp3
alias radios='vlcncurses $SIZE $CLASSIQUE $MEUH $NOVA $FIP'

get-current-song-on-radio-classique() { # Multiline
    curl -s 'http://www.radioclassique.fr/typo3temp/init_player_low.json'  | \
    python -mjson.tool                                                     | \
    grep -E 'author\"|track\"'                                             | \
    sed -s 's/,//g'                                                        | \
    sed -s 's/ *:\"$/\"/g'
}
get-current-song-on-radio-size() { # Multiline
    curl -s 'http://www.size-radio.com/icecast-songtitle.php'                                           \
         -H 'Host: www.size-radio.com'                                                                  \
         -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:28.0) Gecko/20100101 Firefox/28.0'  \
         -H 'Accept: */*'                                                                               \
         -H 'Accept-Language: en-US,en;q=0.5'                                                           \
         -H 'DNT: 1'                                                                                    \
         -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8'                            \
         -H 'X-Requested-With: XMLHttpRequest'                                                          \
         -H 'Referer: http://www.size-radio.com/Icecast/'                                               \
         -H 'Connection: keep-alive'                                                                    \
         -H 'Pragma: no-cache'                                                                          \
         -H 'Cache-Control: no-cache'                                                                   \
         --data 'currentradiourl=size.ice.infomaniak.ch&currentradioport=80%2Fsize-128.mp3' | \
    tail -n 1                                                                               | \
    python -mjson.tool                                                                      | \
    grep -E 'artist\"|song\"'                                                               | \
    sed -s 's/,//g'
}
get-current-song-on-radio-nova() { # Multiline
    ruby "$GIT_BEST_SONGS_REPO"/nova.rb
}

format-for-saving() { # Artist-Track
    echo "$1"                                    | \
    awk -F'"' '{print $4}'                       | \
    perl -pe 'chomp if eof'                   | \
    sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ ~ /g'
}
save-to-best-songs-list() {
    local formattedSongRef="$2"
    local targetFile="$1"
    echo "-" "$(date +"[%d/%m/%y %Hh]")" "$formattedSongRef" >> "$targetFile"
}
array-contains-element() {
    local e
    for e in "${@:2}"; do
        [[ "$e" == "$1" ]] && return 0;
    done;
    return 1
}
save-to-git() {
    pushd . >/dev/null
    cd "$GIT_BEST_SONGS_REPO"
    git add "$1"
    git commit --quiet -m "added $2"
    git stash --quiet
    git pull --quiet origin master
    git push --quiet origin master
    git stash pop --quiet >/dev/null
    popd >/dev/null
}
show-menu() {
    echo -e "Pick a radio:\n"
    local idx=0
    local step=1
    for radio in "${KNOWN_RADIOS[@]}"; do
        echo -e "\t$idx - $radio"
        idx=$((idx + step))
    done;
    read radioChoice
    case "$radioChoice" in
        ''|*[!0-9]*) song ;;
        *) song "${KNOWN_RADIOS[$radioChoice]}" ;;
    esac
    return
}
artist() {
    echo "$1" | head -n 1 | cut -d'"' -f4
}
song() {
    # make sure we target a known radio
    if ( ! array-contains-element "$1" "${KNOWN_RADIOS[@]}" )
    then
        show-menu "$1"
        return
    fi

    local targetFile=$GIT_BEST_SONGS_REPO/$1.md

    case "$2" in
        # list saved songs
        'list') cat "$targetFile"
                return ;;
        # show a randomly chosen saved song and put it in the clipboard
        'rand') local random_song=$(song "$1" list | rl --count 1 | cut -d']' -f2-)
                echo "$random_song" " (saved to clipboard)"
                echo "$random_song" | xclip -sel clip
                return ;;
        # start playing the radio without outputting anything
        'listen'|'play') local radio_name=$(echo "$1" | tr '[:lower:]' '[:upper:]')
                  local radio_url=${!radio_name}
                  radio "$radio_url" >/dev/null 2>&1 &
                  return ;;
    esac

    # display infos on current song to the user
    echo
    echo "Radio $1"
    local current="$(get-current-song-on-radio-"$1")"
    local escaped_current="$(utfout "$current")"
    echo "$escaped_current"
    echo
    song "$1" list | grep "$(artist "$escaped_current")"

    # save to git-versionned file
    read -p "Would you like to save that song (y/N)?"
    [[ "$REPLY" == "y" ]] || return

    local oneLiner=$(format-for-saving "$current")
    save-to-best-songs-list "$targetFile" "$oneLiner"
    save-to-git "$targetFile" "$oneLiner"
}
