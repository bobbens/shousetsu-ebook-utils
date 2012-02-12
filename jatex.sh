#!/bin/sh
# JA -> latex

EDICT="."                     # Edict dictionary folder
EDICT_TMP="/tmp/edict.jatex"  # Temporary file for word lookups
WHITESPACE='[:wh:]'           # Whitespace identifer
NEWLINE='[:nl:]'              # Newline identifer
MECABEUCJP=1                  # By default use utf8 mecab, change 1 to eucjp
IGNORE='*「」。、…”！？　'    # Ignore these in edict lookups

# convert to furigana
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
      [[ $kanji -eq 1 ]] || s1="${s1:1:${#s1}}" # next from kanji/kana
   done
   [[ $kanji -eq 1 ]] && echo -n "\\ruby{$1}{$2}" || echo -n $ret # if kanji is still open,
                                                                  # the whole word can be furiganized
}

# mecab wrapper for utf8 and eucjp mecab
_mecab() {
   while read pipe; do
      [[ $MECABEUCJP -eq 1 ]] && echo "$pipe" | iconv -f utf8 -t eucjp | mecab | iconv -f eucjp -t utf8
      [[ $MECABEUCJP -eq 0 ]] && echo "$pipe" | mecab
   done
}

# get stem of word
_stem() {
   while read pipe; do
      echo "$pipe" | _mecab | awk -F',' '{ print $7 }'
   done
}

# duplicate _mecab code to save iconv calls on eucjp mode
_kakasi() {
   while read pipe; do
      echo "$pipe" | iconv -f utf8 -t eucjp | kakasi -i euc -KH | iconv -f eucjp -t utf8
   done
}

# get mecab reading
_reading() {
   while read pipe; do
      echo "$pipe" | _mecab | awk -F',' '{print $8}'
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
   edic=$(echo "$edic" | sed 's|[^/]*/||;s|/[^/]*/$||;q')
   [ "$edic" ] && echo "$edic"
}

# $1 = Stem
# $2 = Word
# $3 = Meaning
cache_edic() {
   [ "$1" ] && [ "$2" ] && [ "$3" ] || return
   if [[ -f "$EDICT_TMP" ]]; then
      [ "$(grep -w "$1==" "$EDICT_TMP")" ] || echo "$1==$2==$3" >> "$EDICT_TMP"
   else
      echo "$1==$2==$3" >> "$EDICT_TMP"
   fi
}

main()
{
   arg1=${1-1} # process furigana
   arg2=${2-1} # process edict
   arg3=${3-1} # process katakana edict
   [[ -f "$EDICT_TMP" ]] && rm "$EDICT_TMP"

   # [[ $arg1 -eq 1 ]] && echo "\\begin{furigana}"
   while read pipe; do
      local origs=$(echo "$pipe" | sed -e "s/ / $WHITESPACE /g" -e "s/\n/ $NEWLINE /g" | _mecab | awk -F' ' '{print $1}')
      for i in $origs; do
         if [[ $arg1 -eq 1 ]]; then # process furigana
            # check for special treatment
            if   [[ "$i" == "$WHITESPACE" ]]; then
               echo "\\vspace{20mm}\\"
               continue
            elif [[ "$i" == "$NEWLINE" ]]; then
               echo "\\\\\\\\"
               continue
            elif [[ "$i" == "EOS" ]]; then
               continue
            fi
         fi

         # get mecab reading
         reading=$(echo "$i" | _reading)
         if [[ "$i" == "$reading" ]] || [[ ! "$reading" ]]; then
            [[ $arg1 -eq 1 ]] && echo -n "$i"
            [ "$reading" ] && [[ $arg3 -eq 1 ]] && cache_edic "$i" "$i" "$(edic_lookup "$i" "$reading" 0)"
            continue
         fi

         # convert mecab reading to hiragana
         kana=$(echo "$reading" | _kakasi)
         if [[ "$i" == "$kana" ]] || [[ ! "$kana" ]]; then
            [[ $arg1 -eq 1 ]] && echo -n "$i"
            continue
         fi

         # this word contains kanji, furiganize it
         furigana="$(furiganize "$i" "$kana")"
         [[ $arg1 -eq 1 ]] && echo -n "$furigana"
         if [[ $arg2 -eq 1 ]]; then
            local stem="$(echo "$i" | _stem)"
            cache_edic "$stem" "\\$furigana" "$(edic_lookup "$stem" "$kana" 0)"
         fi
      done
   done
   # [[ $arg1 -eq 1 ]] && echo "\\end{furigana}"

   # post process dictionary
   if [[ $arg2 -eq 1 ]] && [[ -f "$EDICT_TMP" ]]; then
      echo "\\newpage \\jahori \\noindent"
      # echo "\\begin{edict}"
      sort "$EDICT_TMP" | while read line; do
         orig=$(echo $line | awk -F'==' '{ print $2 }')
         dict=$(echo $line | awk -F'==' '{ print $3 }')
         [ "$orig" ] && [ "$dict" ] && echo "\\edict{$orig}{$dict}"
      done
      # echo "\\end{edict}"
   fi
}
main "$@"
