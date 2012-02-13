#!/bin/sh
# JA -> latex
#
# Please read before getting brain cancer from the script!
#     This script does many things wrong and is the worst example
#     how things should be done. Furiganizer basically guesses the
#     furigana, and we do lots of piping && extrenal lookups.
#
#     Script is slow as hell, so do bare with me until I rewrite
#     it more properly on something more suited and more effective language.

EDICT="."                     # Edict dictionary folder
EDICT_TMP="/tmp/edict.jatex"  # Temporary file for word lookups
WHITESPACE='whitespace'       # Whitespace identifer
MECABEUCJP=1                  # By default use utf8 mecab, change 1 to eucjp
IGNORE='*「」。、…”！？　'    # Ignore these in edict lookups
ESCAPE='*&^#$%~_{}'           # Escapes all these characters from input
REMOVE='*'                    # Remove from mecab output
REPLACE='!?'                  # Replace these...
SUBSTITUTE='！？'             # ...with these

# check character type
# 0 = kanji
# 1 = hiragana
# 2 = katakana
jchr()
{
   local char=$(printf "%d" \'$@)
   [ $char -gt 19967 ] && [ $char -lt 40896 ] && echo 0 && return
   [ $char -gt 12351 ] && [ $char -lt 12448 ] && echo 1 && return
   [ $char -gt 12447 ] && [ $char -lt 12544 ] && echo 2 && return
   echo -1
}

# convert to furigana [ don't try this at home ]
# $1 = kanji/kana
# $2 = furigana
furiganize() {
   local kanji=0
   local s1="$1"
   local s2="$2"
   local ret=
   while [ -n "$s1" -a -n "$s2" ]
   do
      if [ "${s1:0:1}" != "${s2:0:1}" ]
      then # kanji found
         if [[ $kanji -eq 0 ]]; then
            ret="$ret\\ruby{${s1:0:1}}{${s2:0:1}"
            kanji=1
            s1="${s1:1:${#s1}}" # next from kanji/kana
         else
            ret="$ret${s2:0:1}" # print next furigana for kanji
         fi
      else # furigana
         if [[ $kanji -eq 1 ]]; then
            kanji=0
            ret="$ret}"
         fi
         ret="$ret${s1:0:1}"
      fi
      s2="${s2:1:${#s2}}"                       # next from furigana
      [[ $kanji -eq 0 ]] && s1="${s1:1:${#s1}}" # next from kanji/kana
      [[ $kanji -eq 1 ]] && [[ $(jchr $s1) -eq 0 ]] && ret="$ret}" && kanji=0 # if next letter is kanji as well, then fsck this..
   done
   [[ $kanji -eq 1 ]] && echo -n "\\ruby{$1}{$2}" || echo -n "$ret" # if kanji is still open,
                                                                    # the whole word can be furiganized
}

# remove
_remove() {
   while read -r pipe; do
      echo "$pipe" | sed "s/\([$REMOVE]\)//g"
   done
}

# escape
_escape() {
   while read -r pipe; do
      echo "$pipe" | sed -e 's/\\/\\\\/g' -e "s/\([$ESCAPE]\)/\\\&/g"
   done
}

# replace
_replace() {
   while read -r pipe; do
      local s1="$REPLACE"
      local s2="$SUBSTITUTE"
      local ret="$pipe"
      while [ -n "$s1" -a -n "$s2" ]
      do
         ret="$(echo "$ret" | sed "s/${s1:0:1}/${s2:0:1}/g")"
         s1="${s1:1:${#s1}}"
         s2="${s2:1:${#s2}}"
      done
      echo "$ret"
   done
}

# mecab wrapper for utf8 and eucjp mecab
_mecab() {
   while read -r pipe; do
      [[ $MECABEUCJP -eq 1 ]] && echo "$pipe" | iconv -f utf8 -t eucjp | mecab | iconv -f eucjp -t utf8
      [[ $MECABEUCJP -eq 0 ]] && echo "$pipe" | mecab
   done
}

# get stem of word
_stem() {
   while read -r pipe; do
      echo "$pipe" | _mecab | awk -F',' '{ print $7 }' | _remove
   done
}

# duplicate _mecab code to save iconv calls on eucjp mode
_kakasi() {
   while read -r pipe; do
      echo "$pipe" | iconv -f utf8 -t eucjp | kakasi -i euc -KH | iconv -f eucjp -t utf8
   done
}

# get mecab reading
_reading() {
   while read -r pipe; do
      echo "$pipe" | _mecab | awk -F',' '{print $8}' | _remove
   done
}

# $1 = Stem
# $2 = Kana
parse_edict() {
   local edic=
   local ekfield=$(grep -E "(^|;)$1[ ;(]" "$EDICT/edict2.utf")
   local particles=$(echo "$ekfield" | grep -vF '[')
   if [[ -z $particles ]]; then
      edic=$(echo "$ekfield" | grep "$1.*\[")
      [[ -z $edic ]] && edic=$(grep "\[$1[](]" "$EDICT/edict2.utf")
   else
      edic=$particles
   fi
   [[ -z $edic ]] && edic=$(grep "\[$2[](]" "$EDICT/edict2.utf")
   [[ -z $edic ]] && edic=$(grep -E "(^|;)$1[] (]" "$EDICT/edict2.utf")

   # return
   echo "$edic"
}

# $1 = Lookup word [stem]
# $2 = Kana
# $3 = Giveup on first try?
edic_lookup() {
   local look="$(echo $1 | sed "s/[$IGNORE]//g")"
   [ "$look" ] || return # not good 'word'
   local edic=$(grep "^$1 " "$EDICT/edict2.utf")
   [[ -z $edic ]] && [[ $3 -eq 0 ]] && edic=$(parse_edict "$1" "$2")
   edic="$(echo "$edic" | sed -e 's|[^/]*/||;s|/[^/]*/$||;q')"
   [ "$edic" ] && echo "$edic"
}

# $1 = Stem
check_cache() {
   [[ -f "$EDICT_TMP" ]] || return
   grep -w "$1==" "$EDICT_TMP"
}

# $1 = Stem
# $2 = Word
# $3 = Meaning
cache_edic() {
   [ "$1" ] && [ "$2" ] && [ "$3" ] || return
   mean="$(echo "$3" | _escape | sed -e 's/\//\\slash /g')"
   echo "$1==$2==$mean" >> "$EDICT_TMP"
}

main()
{
   arg1=${1-1} # process furigana
   arg2=${2-1} # process edict
   arg3=${3-1} # process katakana edict
   MECABEUCJP=${4-$MECABEUCJP} # eucjp encoding? default == yes
   [[ -f "$EDICT_TMP" ]] && rm "$EDICT_TMP"

   # [[ $arg1 -eq 1 ]] && echo "\\begin{furigana}"
   OIFS="$IFS"
   IFS='' # preserve whitespace
   while read -r pipe; do
      IFS="$OIFS" # reset ifs
      local origs="$(echo "$pipe" | sed "s/ / $WHITESPACE /g" | _replace | _escape | _mecab | awk -F' ' '{ print $1 }')"
      for i in $origs; do
         if [[ $arg1 -eq 1 ]]; then # process furigana
            # check for special treatment
            if   [[ "$i" == "$WHITESPACE" ]]; then
               #echo "\\jalinebreak"
               continue
            elif [[ "$i" == "EOS" ]]; then
               continue
            fi
         fi

         # get mecab reading
         reading=$(echo "$i" | _reading)
         if [[ "$i" == "$reading" ]] || [[ ! "$reading" ]]; then
            [[ $arg1 -eq 1 ]] && echo -n "$i"
            [[ $arg3 -eq 1 ]] && [ "$reading" ] && [ ! "$(check_cache "$i")" ] && cache_edic "$i" "$i" "$(edic_lookup "$i" "$reading" 0)"
            continue
         fi

         # convert mecab reading to hiragana
         kana=$(echo "$reading" | _kakasi)
         if [[ "$i" == "$kana" ]] || [[ ! "$kana" ]]; then
            [[ $arg1 -eq 1 ]] && echo -n "$i"
            continue
         fi

         # this word contains kanji, furiganize it
         [[ $arg1 -eq 1 ]] && furiganize "$i" "$kana"
         if [[ $arg2 -eq 1 ]]; then
            local stem="$(echo "$i" | _stem)"
            if [ ! "$(check_cache "$stem")" ]; then
               local stemkana="$(echo "$stem" | _reading | _kakasi)"
               cache_edic "$stem" "$(furiganize "$stem" "$stemkana")" "$(edic_lookup "$stem" "$stemkana" 0)"
            fi
         fi
      done

      # every read ends in newline, so add your newline stuff here
      echo "\\janewline"

      # reset IFS for read
      IFS=''
   done
   # [[ $arg1 -eq 1 ]] && echo "\\end{furigana}"

   # post process dictionary
   if [[ $arg2 -eq 1 ]] && [[ -f "$EDICT_TMP" ]]; then
      echo
      echo "\\end{spacing}"
      echo "\\newpage \\jahori \\noindent"
      echo "\\renewcommand{\\rubysep}{0.0ex}"
      # echo "\\begin{edict}"
      #sort "$EDICT_TMP" | while read -r line; do
      cat "$EDICT_TMP" | while read -r line; do
         orig="$(echo "$line" | awk -F'==' '{ print $2 }')"
         dict="$(echo "$line" | awk -F'==' '{ print $3 }')"
         [ "$orig" ] && [ "$dict" ] && echo "\\edict{$orig}{$dict}"
      done
      # echo "\\end{edict}"
   fi
}
main "$@"
