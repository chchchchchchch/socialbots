#!/bin/bash

  OUTDIR=_/PRINT
  OUTDIR=.
  TMP=tmp # TMP PREFIX => EASIFY CLEANUP

  COLORS="#00ff00|#ff0000|#0000ff|#00ffff"
  COLORS="#000000"
  COLORS="#ff0000|#0000ff|#ff00ff"
  COLORS="#444444"

  LEAVEBLANK="65,86-95,104-116,127-134,147-154,
              205-216,225-236,247-254,267-274,
              245,123"

# FUNCTIONS
# --------------------------------------------------------------------------- #
  mkseed(){ openssl enc -aes-256-ctr -pass pass:"$1" \
            -nosalt </dev/zero 2>/dev/null; }


# PREPARE 'LEAVEBLANK' LIST FOR USE WITH GREP
# ------------------------------------------- #
  for B in `echo $LEAVEBLANK | sed 's/,/ /g'`
   do B=`echo $B | #
         sed 's/^[0-9]*$/&-&/' | #
         sed 's/-/ /g'`
      EMPTY="$EMPTY "`seq $B`
  done; 
  EMPTY=`echo $EMPTY | sed 's/[ ]\+/|/g'`

# SELECT AND CONVERT SVG FILES
# ------------------------------------------- #
  for SVG in `ls _/*.svg | shuf -n 10`
   do

    SRCNAME=`basename $SVG | cut -d "." -f 1`
    C1=`echo $COLORS | sed 's/|/\n/g' | #
        shuf -n 1 --random-source=<(mkseed $SRCNAME)`
    C2="$C1"

    cat $SVG | # USELESS USE OF CAT
    sed 's/#[fF]\{6\}/XxXxXx/g' | #
    sed 's/stroke-width:[0-9.]*/stroke-width:5/g' | #
    sed "s/fill:#[0-9a-fA-F]\{6\}/fill:$C1/g" | #
    sed "s/stroke:#[0-9a-fA-F]\{6\}/stroke:$C2/g" | #
    sed "s/XxXxXx/#ffffff/g" | #
    tee > ${TMP}.svg

    if [ ! -f ${SVG%%.*}.pdf ]; then
    inkscape --export-text-to-path \
             --export-pdf=${SVG%%.*}.pdf \
             ${TMP}.svg
      else
    echo "${SVG%%.*}.pdf EXISTS"
    fi
  done

# A LIST OF PDF FILES
# ------------------------------------------- #
  PDFALL=`ls _/*.pdf` # USETHESE=
  PDFALL=`printf "${PDFALL}\n%.0s" {1..100} | #
          shuf -n 400`


# PREPARE LATEX INPUT LIST
# ------------------------------------------- #
  CNT=1
  while [ $CNT -le 400 ]
   do
     ISEDGE=`echo $((CNT%20)) | # MODULO
             egrep -w "0|1"   | # CONTAINS THIS
             wc -l`             # COUNT MATCH
     LEAVEBLANK=`echo $CNT         | # THE COUNT
                 egrep -w "$EMPTY" | # IS IN $EMPTY
                 wc -l`              # COUNT MATCH
    #  if [ $LEAVEBLANK == 1 ] ||
    #     [ $((RANDOM%100+1)) -gt 70 ] &&
    #     [ $ISEDGE != 1 ]
    #   then
    #       PDFALL=`echo $PDFALL   | #
    #               sed "s/ /\n/g" | #
    #               sed "${CNT}s/$/,{}/"`
    #  fi

      if [ $LEAVEBLANK == 1 ]
       then
           PDFALL=`echo $PDFALL   | #
                   sed "s/ /\n/g" | #
                   sed "${CNT}s/$/,{}/"`
           LAST="BLANK"
      else
           if [ $((RANDOM%100+1)) -gt 65 ] &&
              [ $ISEDGE != 1 ] && [ T$LAST != TBLANK ]
           then
           PDFALL=`echo $PDFALL   | #
                   sed "s/ /\n/g" | #
                   sed "${CNT}s/$/,{}/"`
           LAST="BLANK"
           else LAST="BOT"
           fi
      fi

      CNT=`expr $CNT + 1`
  done
  PDFALL=`echo $PDFALL | sed 's/ /,/g' | sed '$s/,$//'`



  echo "\documentclass[9pt]{scrbook}"                    >  ${TMP}.tex
  echo "\usepackage{pdfpages}"                           >> ${TMP}.tex
  echo "\usepackage{geometry}"                           >> ${TMP}.tex
  echo "\geometry{paperwidth=426mm,paperheight=600mm}"   >> ${TMP}.tex
  echo "\begin{document}"                                >> ${TMP}.tex
  echo "\includepdfmerge[offset=0 100,delta=-2 0,"       >> ${TMP}.tex
  echo "       nup=20x20,noautoscale=true,scale=0.15]"   >> ${TMP}.tex
  echo "{$PDFALL}"                                       >> ${TMP}.tex
  echo "\end{document}"                                  >> ${TMP}.tex

  pdflatex -interaction=nonstopmode \
           -output-directory $OUTDIR \
           tmp.tex # > /dev/null

  pdftk tmp.pdf background tmp/grid.pdf output tmp+grid.pdf



  exit 0;
