#!/usr/bin/env bash

INURLS=( http://ncode.syosetu.com/n8725k/
         http://ncode.syosetu.com/n8709j/
         http://ncode.syosetu.com/n5174n/
         http://ncode.syosetu.com/n6366u/
         http://ncode.syosetu.com/n6963w/ 
         http://ncode.syosetu.com/n0126r/ 
         http://ncode.syosetu.com/n8462u/ )

for x in "${INURLS[@]}"
do
   perl mojobob "$x"
done
