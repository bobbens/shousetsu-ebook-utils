#!/usr/bin/env zsh

# Options
FURIGANA=1 # Generate furigana for text, 0 is disable, 1 is enable.
DICTIONARY=1 # Generate dictionary at the end of the text. 0 is disable, 1 is enable.
KATAKANA=1 # Include katakana in the dictionary. 0 is disable, 1 is enable.

# Directory paths
INDIR=scrape_data
TMPDIR=.latex_out
OUTDIR=pdfs

# Latex xstuff
LATHEAD=head.tex
LATTAIL=tail.tex

#set -x

test -d $TMPDIR || mkdir $TMPDIR
test -d $OUTDIR || mkdir $OUTDIR

for FILEPATH in $INDIR/**/*.txt; do
   # Parse name and such
   FILE=`basename "$FILEPATH"`
   FILE=${FILE%.txt}
   FILE=${FILE//[()]}
   AUTHOR=${FILE%-*}
   TITLE=${FILE#*-}
   EUCJP=${1-1}

   # Working files
   TTEXT="$TMPDIR/$FILE.txt"
   TFILE="$TMPDIR/$FILE.tex"
   OFILE="$OUTDIR/${FILEPATH#$INDIR/}"
   OFILE="${OFILE%.txt}.pdf"

   # If already created avoid recreation
   test -f "$OFILE" && continue

   # More temp stuff
   OTITLE="$TMPDIR/title"
   OBASE=`dirname $OFILE`
   test -d "$OBASE" || mkdir -p "$OBASE"

   # Begin processing
   echo "Processing $AUTHOR - $TITLE"

   # Generate the tex
   echo -n "   Generated TEX..."
   TSTART=$SECONDS
   echo "\storytitle{$TITLE}{$AUTHOR}" > "$OTITLE"
   cat "$FILEPATH" | sh jatex.sh $FURIGANA $DICTIONARY $KATAKANA $EUCJP > "$TTEXT"
   cat "$LATHEAD" "$OTITLE" "$TTEXT" "$LATTAIL" > "$TFILE"
   TEND=$SECONDS
   echo " $((TEND-TSTART)) sec"

   # Generate the pdf
   echo -n "   Generating PDF..."
   TSTART=$SECONDS
   (cd "$TMPDIR"; xelatex "$FILE" > /dev/null)
   TEND=$SECONDS
   echo " $((TEND-TSTART)) sec"

   # Copy result over
   cp "$TMPDIR/$FILE.pdf" "$OFILE" || exit
done

#rm -r .latex_out

