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

   # Working files
   TTEXT="$TMPDIR/$FILE.txt"
   TFILE="$TMPDIR/$FILE.tex"
   OFILE="$OUTDIR/$FILE.pdf"

   # If already created avoid recreation
   test -f "$OFILE" && continue

   OTITLE="$TMPDIR/title"

   # Begin processing
   echo "Processing $AUTHOR - $TITLE"

   # Generate the tex
   echo "   Generated TEX..."
   echo "\storytitle{$TITLE}{$AUTHOR}" > "$OTITLE"
   cat "$FILEPATH" | sh jatex.sh $FURIGANA $DICTIONARY $KATAKANA > "$TTEXT"
   cat "$LATHEAD" "$OTITLE" "$TTEXT" "$LATTAIL" > "$TFILE"

   # Generate the pdf
   echo "   Generating PDF..."
   (cd "$TMPDIR"; xelatex "$FILE" > /dev/null)

   # Copy result over
   cp "$TMPDIR/$FILE.pdf" "$OFILE" || exit

   exit
done

#rm -r .latex_out

