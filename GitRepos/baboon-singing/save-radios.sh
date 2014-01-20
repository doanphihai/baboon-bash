GIT_BEST_SONGS_REPO=$HOME/GitRepos/baboon-singing
KNOWN_RADIOS=('classique' 'size')

get-current-song-on-radio-classique() { # Multiline
    curl -s 'http://www.radioclassique.fr/typo3temp/init_player_low.json'  | \
    underscore print                                                       | \
    grep -E 'author\"|track\"'                                             | \
    sed -s 's/,//g'                                                        | \
    sed -s 's/ *:\"$/\"/g'
}

get-current-song-on-radio-size() { # Multiline
    curl -s 'http://www.size-radio.org/icecast-songtitle.php'                                           \
         -H 'Host: www.size-radio.org'                                                                  \
         -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:28.0) Gecko/20100101 Firefox/28.0'  \
         -H 'Accept: */*'                                                                               \
         -H 'Accept-Language: en-US,en;q=0.5'                                                           \
         -H 'DNT: 1' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8'                \
         -H 'X-Requested-With: XMLHttpRequest'                                                          \
         -H 'Referer: http://www.size-radio.org/Icecast/'                                               \
         -H 'Connection: keep-alive'                                                                    \
         -H 'Pragma: no-cache'                                                                          \
         -H 'Cache-Control: no-cache'                                                                   \
         --data 'currentradiourl=size.ice.infomaniak.ch&currentradioport=80%2Fsize-128.mp3' | \
    tail -n 1                                                                               | \
    underscore print                                                                        | \
    grep -E 'artist\"|song\"'                                                               | \
    sed -s 's/,//g'
}
format-for-saving() { # Artist-Track
    echo "$1"                   | \
    grep -Eo '\"[^"]+\"$'       | \
    sed 's/\"//g'               | \
    perl -i -pe 'chomp if eof'  | \
    tr '\n' "-"
    echo
}
save-to-best-songs-list() {
    local formattedSongRef="$2"
    local targetFile=$GIT_BEST_SONGS_REPO/$1.md
    echo $formattedSongRef >> $targetFile
}
array-contains-element() {
    local e
    for e in "${@:2}"; do
        [[ "$e" == "$1" ]] && return 0;
    done;
    return 1
}
song() {
    # make sure we target a known radio
    if ( ! array-contains-element "$1" "${KNOWN_RADIOS[@]}" )
    then
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
    fi

    # display infos on current song to the user
    echo
    echo "Radio $1"
    local current="$(get-current-song-on-radio-$1)"
    echo "$current"
    echo

    # save to git-versionned file
    read -p "Would you like to save that song (y/n)?"
    [[ "$REPLY" == "y" ]] || return

    local oneLiner=$(format-for-saving "$current")
    save-to-best-songs-list "$1" "$oneLiner"

    # commit and push to git remote
    read -p "Would you like to update the git repository (y/n)?"
    [[ "$REPLY" == "y" ]] || return

    pushd .
    cd "$GIT_BEST_SONGS_REPO"
    git add .
    git commit -m "added $oneLiner"
    git push origin master
    popd
}
