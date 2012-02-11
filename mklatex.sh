#!/usr/bin/env zsh

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

for FILEPATH in $INDIR/**/*web*.txt; do
   # Parse name and such
   FILE=`basename "$FILEPATH"`
   FILE=${FILE%.txt}
   FILE=${FILE//[()]}
   AUTHOR=${FILE%-*}
   TITLE=${FILE#*-}

   # Working files
   TFILE="$TMPDIR/$FILE.tex"
   OFILE="$OUTDIR/$FILE.pdf"

   # Generate the pdf
   echo "Generating PDF for $AUTHOR - $TITLE"
   cat "$LATHEAD" "$FILEPATH" "$LATTAIL" > "$TFILE"
   (cd "$TMPDIR"; xelatex "$FILE" > /dev/null)

   # Copy result over
   cp "$TMPDIR/$FILE.pdf" "$OFILE" || exit
done

#rmdir $OUTDIR

