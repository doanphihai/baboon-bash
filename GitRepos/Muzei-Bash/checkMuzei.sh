#!/usr/bin/env bash
# This script will check for updates on Muzei JSON
# If it is updated it will start MuzeiBash.sh

muzeiDir=~/Pictures/Muzei
mkdir -p $muzeiDir
cd $muzeiDir

if ! [ -f ./muzeich.json ]
then
    echo "First use <3 fetching latest Muzei metadatas..."
    curl -s -o muzeich.json 'https://muzeiapi.appspot.com/featured?cachebust=1'
    ~/GitRepos/Muzei-Bash/MuzeiBash.sh
else
    echo "Fetching latest Muzei metadatas..."
    curl -s -o muzeich2.json 'https://muzeiapi.appspot.com/featured?cachebust=1'
    if [ "$(cat muzeich.json)" != "$(cat muzeich2.json)" ]
    then
        echo "New wallpaper found!"
        mv muzeich2.json muzeich.json
        ~/GitRepos/Muzei-Bash/MuzeiBash.sh
    else
        echo "Wallpaper is already up to date!"
    fi
fi
