#!/bin/bash

# WAS: PERMUTE SVG LAYERS; IS: A BIT MORE COMPLICATED                         #
# --------------------------------------------------------------------------- #
# copyright (c) 2017 Christoph Haag                                           #
# --------------------------------------------------------------------------- #

# This is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
# 
# The software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License below for more details.
# 
# -> http://www.gnu.org/licenses/gpl.txt

# --------------------------------------------------------------------------- #
# CONFIGURATION 
# --------------------------------------------------------------------------- #
  OUTDIR=_
  SRC=E/000000_notabotyet.svg
# --------------------------------------------------------------------------- #
# CONFIGURATION 
# --------------------------------------------------------------------------- #
  source lib/sh/shuffle.functions
 
# --------------------------------------------------------------------------- #
# CHECK INPUT
# --------------------------------------------------------------------------- #
  if [ `echo $* | wc -c` -gt 1 ]; then 
        INSERTTXT="YES";NOISE="$*"
   else INSERTTXT="NO"; NOISE="" ; fi

# =========================================================================== #
# DO IT NOW!
# =========================================================================== #
  SVG=$SRC
# --------------------------------------------------------------------------- #
# MOVE ALL LAYERS ON SEPARATE LINES IN A TMP FILE
# --------------------------------------------------------------------------- #
  sed ':a;N;$!ba;s/\n//g' $SVG           | # REMOVE ALL LINEBREAKS
  sed 's/<g/\n&/g'                       | # MOVE GROUP TO NEW LINES
  sed '/groupmode="layer"/s/<g/4Fgt7R/g' | # PLACEHOLDER FOR LAYERGROUP OPEN
  sed ':a;N;$!ba;s/\n/ /g'               | # REMOVE ALL LINEBREAKS
  sed 's/4Fgt7R/\n<g/g'                  | # RESTORE LAYERGROUP OPEN + NEWLINE
  sed 's/display:none/display:inline/g'  | # MAKE VISIBLE EVEN WHEN HIDDEN
 #grep -v 'label="XX_'                   | # REMOVE EXCLUDED LAYERS
  sed 's/<\/svg>/\n&/g'                  | # CLOSE TAG ON SEPARATE LINE
  sed "s/^[ \t]*//"                      | # REMOVE LEADING BLANKS
  tr -s ' '                              | # REMOVE CONSECUTIVE BLANKS
  tee > ${SVG%%.*}.tmp                     # WRITE TO TEMPORARY FILE
# --------------------------------------------------------------------------- #
# FIND LAYERS THAT ALLOW INPUT
# --------------------------------------------------------------------------- #
  LAYERS2INPUT=`grep "flowRoot" ${SVG%%.*}.tmp     | #
                sed '/^<g/s/>/&\n/g'               | # FIRST '>' ON NEWLINE
                grep ':groupmode="layer"'          | #
                sed '/^<g/s/scape:label/\nlabel/'  | #
                grep ^label                        | #
                grep -v "XX_"                      | # IGNORE XXCLUDED LAYERS
                cut -d "\"" -f 2`

# --------------------------------------------------------------------------- #
# GENERATE CODE FOR FOR-LOOP TO EVALUATE COMBINATIONS
# --------------------------------------------------------------------------- #
  # RESET (IMPORTANT FOR 'FOR'-LOOP)
  LOOPSTART="";VARIABLES="";LOOPCLOSE="";CNT=0

  for BASETYPE in `sed 's/>/&\n/g' ${SVG%%.*}.tmp    | # ALL '>' ON NEWLINE
                   grep ':groupmode="layer"'         | # SELECT LAYER GROUPS
                   sed '/^<g/s/scape:label/\nlabel/' | # PUT NAME LABEL ON NL
                   grep ^label                       | # EXTRACT NAME
                   grep -v "XX_"                     | # IGNORE XXCLUDED LAYERS
                   cut -d "\"" -f 2                  | #
                   cut -d "-" -f 1                   | #
                   sort -u`
   do
       ADDINPUTLAYERS=`echo $LAYERS2INPUT | grep $BASETYPE`
       ALLOFTYPE=`sed ':a;N;$!ba;s/\n/ /g' ${SVG%%.*}.tmp  | #
                  sed 's/scape:label/\nlabel/g'            | #
                  grep ^label                              | #
                  grep -v "XX_"                            | # IGNORE XXCLUDED LAYERS
                  cut -d "\"" -f 2                         | #
                  grep $BASETYPE                           | #
                  sort -u                                  | #
                  shuf -n 4`
       ALLOFTYPE=`echo $ALLOFTYPE $ADDINPUTLAYERS | #
                  sed 's/ /\n/g' | sort -u`

       LOOPSTART=${LOOPSTART}"for V$CNT in $ALLOFTYPE; do "
       VARIABLES=${VARIABLES}'$'V${CNT}" "
       LOOPCLOSE=${LOOPCLOSE}"done; "
       CNT=`expr $CNT + 1`
  done

# --------------------------------------------------------------------------- #
# EXECUTE CODE FOR FOR-LOOP TO EVALUATE COMBINATIONS
# --------------------------------------------------------------------------- #
  KOMBILIST=kombinationen.list ; if [ -f $KOMBILIST ]; then rm $KOMBILIST ; fi
  eval ${LOOPSTART}" echo $VARIABLES >> $KOMBILIST ;"${LOOPCLOSE}

  LAYERS2INPUT=`echo $LAYERS2INPUT | sed 's/ /|/g'`
  if [ "Y$INSERTTXT" == "YYES" ];then GREP="egrep"; else GREP="egrep -v"; fi
# --------------------------------------------------------------------------- #
# WRITE SVG FILES ACCORDING TO POSSIBLE COMBINATIONS
# --------------------------------------------------------------------------- #
  SVGHEADER=`head -n 1 ${SVG%%.*}.tmp`   

  for KOMBI in `cat $KOMBILIST               | # USELESS USE OF CAT
                eval $GREP \"$LAYERS2INPUT\" | #
                shuf                         | # DOES THIS MAKE SENSE?
                sed 's/ /DHSZEJDS/g'`          # PLACEHOLDER FOR SPACES
   do
      if [ "$DONE" != "YES" ];then

            KOMBI=`echo $KOMBI | sed 's/DHSZEJDS/ /g'`
             NAME=`echo $KOMBI | md5sum | #
                   cut -d " " -f 1 | cut -c 1-12 | #
                   tr [:lower:] [:upper:]`
            SVGOUT=$OUTDIR/B${NAME}.svg

    # ONLY WRITE IF NOT YET DONE
    # -------------------------------------------------------------------  #

      if [ ! -f $SVGOUT ] && [ "$DONE" != "YES" ];then

      echo "WRITING: $SVGOUT"

      grep -n 'label="XX_DEKO' ${SVG%%.*}.tmp   | #
      shuf -n 2 --random-source=<(mkseed $NAME) | # SELECT (NOT SO) RANDOM
      sed 's/display:inline/display:none/g'       > ${SVGOUT}.tmp

      head -n 1 ${SVG%%.*}.tmp                           >  $SVGOUT
      for  LAYERNAME in `echo $KOMBI`
        do grep -n "label=\"$LAYERNAME\"" ${SVG%%.*}.tmp >> ${SVGOUT}.tmp
      done
      cat ${SVGOUT}.tmp | sort -n | cut -d ":" -f 2-     >> $SVGOUT
      echo "</svg>"                                      >> $SVGOUT
      rm ${SVGOUT}.tmp

      INJECT=`echo $NOISE            | # ASSUMED UTF-8
              sed "s/&/\\\\\&amp;/g" | #
              sed "s/\"/\\\\\"/g"`     #

    # TODO: SUBSTITUTE ONLY FIRST APPEARANCE, 
    #       BLANK OUT REST
      sed -i "s/FOOXXX87653/$INJECT/" $SVGOUT

      DONE="YES"

      else
           sleep 0; # echo "$SVGOUT exists"
      fi

      fi
  done

# --------------------------------------------------------------------------- #
# REMOVE TEMP FILES
# --------------------------------------------------------------------------- #
  rm ${SVG%%.*}.tmp $KOMBILIST
# =========================================================================== #

exit 0;

