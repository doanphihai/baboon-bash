GIT_BEST_SONGS_REPO=$HOME/GitRepos/baboon-singing
KNOWN_RADIOS=('classique' 'size')

get-current-song-on-radio-classique() { # Multiline
    curl -s 'http://www.radioclassique.fr/typo3temp/init_player_low.json' | \
    underscore print | \
    grep -E 'author\"|track\"' | \
    sed -s 's/,//g' | \
    sed -s 's/ *:\"$/\"/g'
}
get-current-song-on-radio-size() { # Multiline
    curl -s 'http://size-radio.com//radio/playingAndPlayed/index.php?' | \
    underscore print | \
    grep -E 'artist\"|title\"' | \
    sed -s 's/,//g'
}
format-for-saving() { # Artist-Track
    echo "$1" | \
    grep -Eo '\"[^"]+\"$' | \
    sed 's/\"//g' | \
    perl -i -pe 'chomp if eof' | \
    tr '\n' "-"
    echo
}
save-to-best-songs-list() {
    local formattedSongRef=$(format-for-saving "$2")
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
    save-to-best-songs-list "$1" "$current"

    # commit and push to git remote

}
