#!/usr/bin/env bash
# This script will check for updates on Muzei JSON
# If it is updated it will start MuzeiBash.sh

muzeiDir=~/Pictures/Muzei
mkdir -p $muzeiDir
cd $muzeiDir

if ! [ -f ./muzeich.json ]
then
  curl -o muzeich.json 'https://muzeiapi.appspot.com/featured?cachebust=1'
  ~/GitRepos/Muzei-Bash/MuzeiBash.sh
else
  curl -o muzeich2.json 'https://muzeiapi.appspot.com/featured?cachebust=1'
  if [ "$(cmp muzeich.json muzeich2.json)" ]
    then
      mv muzeich2.json muzeich.json
      ~/GitRepos/Muzei-Bash/MuzeiBash.sh
  fi
fi
