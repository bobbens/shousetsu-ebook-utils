#!/usr/bin/env bash
# Run sentences @ http://tatoeba.org/eng/download_tatoeba_example_sentences
# through jatex!

# Options
FURIGANA=1 # Generate furigana for text, 0 is disable, 1 is enable.
DICTIONARY=1 # Generate dictionary at the end of the text. 0 is disable, 1 is enable.
HIRAGANA=1 # Include hiragana words in the dictionary. 0 is disable, 1 is enable.
KATAKANA=1 # Include katakana words in the dictionary. 0 is disable, 1 is enable.
ENGLISH=1 # Include english sentences in the dictionary. 0 is disable, 1 is enable.
RANDOMIZE=1 # Randomize sentence order?
PDF_TO_GENERATE=10 # Number of PDF's to generate
BLOCKS_PER_PDF=10 # Number of blocks per PDF, set to 0 to generate much as we can
SENTENCES_PER_BLOCK=10 # Number of sentences per block (page for JPN, page for EDICT && ENG)

SENTENCES_SOURCE="http://tatoeba.org/files/downloads/sentences.csv"
LINKS_SOURCE="http://tatoeba.org/files/downloads/links.csv"
LINKS_FILE="links.csv"
SENTENCES_FILE="sentences.csv"
OUTPUT_FILE="tatoeba.csv"
OUTFILE_TEMPLATE="sentences" # x.pdf fill be appended, where x = number

# Directory paths
OUTDIR=pdfs
TMPDIR=.latex_out

# Latex xstuff
LATHEAD=head-hor.tex
LATTAIL=tail.tex


main()
{
   EUCJP=${1-1}

   echo "Create directories..."
   test -d $TMPDIR || mkdir $TMPDIR
   test -d $OUTDIR || mkdir $OUTDIR

   echo "Checking for \"$SENTENCES_FILE\"..."
   [[ -f "$SENTENCES_FILE" ]] || wget "$SENTENCES_SOURCE" -O "$SENTENCES_FILE"
   [[ -f "$LINKS_FILE" ]]     || wget "$LINKS_SOURCE" -O "$LINKS_FILE"

   echo "Check for \"$OUTPUT_FILE\"..."
   [[ -f "$OUTPUT_FILE" ]]    || python tatoeba_extract.py

   let i=0
   let l=$SENTENCES_PER_BLOCK
   let p=1
   let b=1
   let inc=$((SENTENCES_PER_BLOCK*BLOCKS_PER_PDF))
   ebuf=
   jbuf=
   TFILE="$TMPDIR/tatoeba_temp.tex"
   PFILE="$TMPDIR/tatoeba.tex"
   rm -f $TFILE
   while read line
   do
      # Split text
      jpn=$(echo "$line" | cut -f1)
      eng=$(echo "$line" | cut -f2)

      # Accumulate buffer
      jbuf="$jbuf$jpn\n"
      ebuf="$ebuf$eng\n"

      # Time to dump
      if [[ $i -gt 0 && $(($i % $SENTENCES_PER_BLOCK)) -eq 0 ]]; then
         # Process the text and clear buffer
         buf="$jbuf\nnojatex\nclearpage\n$ebuf\nclearpage\njatex"
         echo -n " $b"
         echo -e "$buf" | bash jatex.sh $FURIGANA $DICTIONARY $HIRAGANA $KATAKANA $EUCJP >> "$TFILE"
         if [[ $b -lt $BLOCKS_PER_PDF ]]; then
            echo "\\clearpage{\\textstart" >> "$TFILE"
         fi
         #echo -e "$buf"
         let b=$b+1
         ebuf=
         jbuf=

         # Time to generate output
         if [[ $(($i % $inc)) -eq 0 ]]; then
            OFILE="$OUTDIR/${OUTFILE_TEMPLATE}-$p.pdf"

            TSTART=$SECONDS
            echo
            echo -n "   Generating PDF '$OFILE'..."

            # Generate the tex
            cat "$LATHEAD" > "$PFILE"
            echo "\storytitle{「例えば」の例文 - $p}{}" >> "$PFILE"
            cat "$TFILE" >> "$PFILE"
            cat "$LATTAIL" >> "$PFILE"

            # Generate the pdf
            (cd "$TMPDIR"; xelatex "`basename $PFILE`" > /dev/null)
            TEND=$SECONDS
            echo " $((TEND-TSTART)) sec"

            # Copy over
            cp "${PFILE%.tex}.pdf" "$OFILE" || exit
            rm -f $TFILE
            let p=$p+1
            let b=1
         fi
      fi

      let i=$i+1
      [[ $p -gt $PDF_TO_GENERATE ]] && break
   done < "$OUTPUT_FILE"
}
main $@
