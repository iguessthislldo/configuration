#!/usr/bin/env bash

FONTS_DIR=/usr/share/fonts/TTF

if [ ! -d $FONTS_DIR ]
then
    mkdir $FONTS_DIR
fi
cp ./*.ttf $FONTS_DIR
if [ $? -eq 0 ]
then
    chmod -R 777 $FONTS_DIR
    fc-cache -f -v
fi
