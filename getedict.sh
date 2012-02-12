#!/usr/bin/env sh


if [[ -f ./edict2.utf ]]; then
   echo "Already have edict..."
   exit
fi

echo "Downloading edict..."
curl -s ftp://ftp.monash.edu.au/pub/nihongo/edict2.gz | gunzip | iconv -f eucjp -t utf8 > edict2.utf

