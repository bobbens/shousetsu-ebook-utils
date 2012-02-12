#!/usr/bin/env sh


[[ -f ./edict2.utf ]] && exit

curl -s ftp://ftp.monash.edu.au/pub/nihongo/edict2.gz | gunzip | iconv -f eucjp -t utf8 > edict2.utf

