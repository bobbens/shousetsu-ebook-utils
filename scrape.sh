#!/usr/bin/env bash

INURLS=( http://ncode.syosetu.com/n8725k/
         http://ncode.syosetu.com/n8709j/ )

for x in "${INURLS[@]}"
do
   echo perl mojobob "$x"
done
