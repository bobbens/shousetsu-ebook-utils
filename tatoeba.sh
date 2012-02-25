#!/bin/sh
# Run sentences @ http://tatoeba.org/eng/download_tatoeba_example_sentences
# through jatex!

# Options
FURIGANA=1 # Generate furigana for text, 0 is disable, 1 is enable.
DICTIONARY=1 # Generate dictionary at the end of the text. 0 is disable, 1 is enable.
HIRAGANA=1 # Include hiragana words in the dictionary. 0 is disable, 1 is enable.
KATAKANA=1 # Include katakana words in the dictionary. 0 is disable, 1 is enable.
ENGLISH=1 # Include english sentences in the dictionary. 0 is disable, 1 is enable.
PDF_TO_GENERATE=1 # Number of PDF's to generate
BLOCKS_PER_PDF=2 # Number of blocks per PDF, set to 0 to generate much as we can
SENTENCES_PER_BLOCK=10 # Number of sentences per block (page for JPN, page for EDICT && ENG)

SENTENCES_SOURCE="http://tatoeba.org/files/downloads/sentences.csv"
SENTENCES_FILE="sentences.csv"
OUTFILE_TEMPLATE="sentences" # x.pdf fill be appended, where x = number

# Directory paths
OUTDIR=pdfs
TMPDIR=.latex_out

# Latex xstuff
LATHEAD=head.tex
LATTAIL=tail.tex

# Global
JPN=
ENG=

# $1 = Number of lines parsed
# $2 = Block to start from
magic()
{
   let CNT=$BLOCKS_PER_PDF
   let i=0
   let l=$2
   let MAX=$1
   while [ $CNT -eq 0 ] || [ $i -lt $CNT ]; do
      echo "$JPN" | head -n${l} | tail -n${SENTENCES_PER_BLOCK}
      echo "nojatex"
      echo "clearpage"
      echo "$ENG" | head -n${l} | tail -n${SENTENCES_PER_BLOCK}
      echo "clearpage"
      echo "jatex"
      let l=$l+$SENTENCES_PER_BLOCK
      let i=$i+1
      [[ $l -gt $MAX ]] && break
   done
}

main()
{
   EUCJP=${1-1}

   echo "Create directories..."
   test -d $TMPDIR || mkdir $TMPDIR
   test -d $OUTDIR || mkdir $OUTDIR

   echo "Checking for \"$SENTENCES_FILE\"..."
   [[ -f "$SENTENCES_FILE" ]] || wget "$SENTENCES_SOURCE" -O "$SENTENCES_FILE"

   echo "Retieving sentences from \"$SENTENCES_FILE\"..."
   JPN="$(sed -n 's/.*[0-9]\tjpn\t//p' "$SENTENCES_FILE")"
   ENG="$(sed -n 's/.*[0-9]\teng\t//p' "$SENTENCES_FILE")"
   CNT=$(echo "$JPN" | wc -l)
   echo

   let i=0
   let l=$SENTENCES_PER_BLOCK
   let inc=$((SENTENCES_PER_BLOCK*BLOCKS_PER_PDF))
   while [ $PDF_TO_GENERATE -eq 0 ] || [ $i -lt $PDF_TO_GENERATE ]; do
      # Generate the tex
      echo -n "   Generated TEX..."
      TSTART=$SECONDS
      TFILE="$TMPDIR/tatoeba.tex"
      OFILE="$OUTDIR/${OUTFILE_TEMPLATE}-${i}.pdf"
      cat "$LATHEAD" > "$TFILE"
      echo "\storytitle{「例えば」の例文}{}" >> "$TFILE"
      magic $CNT $l | sh jatex.sh $FURIGANA $DICTIONARY $HIRAGANA $KATAKANA $EUCJP >> "$TFILE"
      cat "$LATTAIL" >> "$TFILE"
      TEND=$SECONDS
      echo " $((TEND-TSTART)) sec"

      # Generate the pdf
      echo -n "   Generating PDF..."
      TSTART=$SECONDS
      (cd "$TMPDIR"; xelatex "`basename $TFILE`" > /dev/null)
      TEND=$SECONDS
      echo " $((TEND-TSTART)) sec"

      # Copy result over
      cp "${TFILE%.tex}.pdf" "$OFILE" || exit

      let l=$l+$inc
      let i=$i+1
      [[ $l -gt $CNT ]] && break
   done
}
main $@
