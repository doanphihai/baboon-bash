#!/usr/bin/env bash

######Initial stuff######
muzeiDir=~/Pictures/Muzei
mkdir -p $muzeiDir/Wallpaper
cd $muzeiDir

######Functions##########
function setWallpaperLinux(){
    if [ "$(which gsettings)" ]
    then
        echo "Gnome-settings-daemons detected, setting wallpaper with gsettings..."
        gsettings set org.gnome.desktop.background picture-uri file://$muzeiDir/Wallpaper/$imageFile
    else
        echo "Salvage your ass, get Linux."
        exit
    fi
}
function notifytestLinux(){
    if ! [ "$(which notify-send)" ]
    then
        echo "Please install a notification server for a better experience."
    fi
}

######Needed packages######
case "$OSTYPE" in
  linux* | *BSD*) notifytestLinux ;;
  *)              echo "Salvage your ass, get Linux."  && exit ;;
esac
if ! [ "$(which jq)" ]
then
  echo "You need jq to use this."
  exit
fi

######Get the Muzei JSON and parse it######
curl -s -o muzei.json 'https://muzeiapi.appspot.com/featured?cachebust=1'
imageUri=`jq '.imageUri' $muzeiDir/muzei.json | sed s/\"//g`
imageFile=`basename $imageUri`
title=`jq '.title' $muzeiDir/muzei.json | sed s/\"//g`
byline=`jq '.byline' $muzeiDir/muzei.json | sed s/\"//g`

######Get the latest wallpaper######
cd Wallpaper
if [ -f $imageFile ]
then
  echo "File $imageFile exists."
else
  echo "File $imageFile does not exist, downloading..."
  curl -s -O $imageUri
fi

######Set the wallpaper######
setWallpaperLinux

######Send a notification######
cd $muzeiDir
if [ -f MuzeiLogo.png ];
then
  echo "Logo already exists."
else
  echo "Logo doesn't exist, downloading..."
  curl -s -O "https://raw.github.com/Feminist-Software-Foundation/Muzei-Bash/master/MuzeiLogo.png"
fi
notify-send "New wallpaper: '$title'" "$byline" -i $muzeiDir/MuzeiLogo.png

######Clean up old wallpapers######
echo "Cleaning up old files..."
find $muzeiDir/Wallpaper -ctime +30 -exec rm {} +
