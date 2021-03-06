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
  FOO="FOOXXX87653"
  SVGWIDTH="800"
# --------------------------------------------------------------------------- #
# CONFIGURATION 
# --------------------------------------------------------------------------- #
  source lib/sh/shuffle.functions
 
# --------------------------------------------------------------------------- #
# CHECK INPUT
# --------------------------------------------------------------------------- #
  if [ `echo $* | sed 's/ [^ ]*\.kombi\b//g' | wc -c` -le 1 ]; then 
        INPUTTXT="NO";NOISE="";CHARSNEEDED="0"
  else  INPUTTXT="YES";
        NOISE=`echo "$*" | sed 's/ [^ ]*\.kombi\b//g' | sed 's/^[ ]*//g'`
      # CHECK AND EXPAND URLS
      # ----------------------------------------------------------------  #
         NOISE=`echo "$NOISE" | sed 's/\\\\\//\//g'` # DE-ESCAPE
         for URL in `echo "$NOISE"      | # START WITH MESSAGE
                     sed 's/ /\n/g'     | # PUT ON SEPARATE LINES
                     grep "^http.\?://" | # SELECT URLS
                     sort -u `            # ONE TIME ONLY
          do XRL=`curl -sIL "$URL"      | # CHECK URL
                  grep "^Location"      | # SELECT LOCATION
                  cut -d ":" -f 2-      | # INFO ONLY
                  sed 's/^[ ]*//'       | # RM LEADING BLANKS
                  tr -d '\r'`             # RM CARRIAGE RETURN
             if [ `echo "$XRL" | wc -c` -le 1 ] &&
                [ `curl -s -o /dev/null -w "%{http_code}" \
                   -I "$URL"` == '200' ];then XRL="$URL"; fi
               NOISE=`echo "$NOISE" | sed "s|$URL|$XRL|g"` # COLLECT
         done; NOISE=`echo "$NOISE" | sed 's/\//\\\\\//g'` # RE-ESCAPE
       # ----------------------------------------------------------------  #
        CHARSNEEDED=`echo "$NOISE" | wc -c`; fi
  KOMBI=`echo "$*" | sed 's/ /\n/g' | grep "[0-9]*\.kombi" | head -n 1`
         if [ -f "$KOMBI" ];then INPUTKOMBI="YES";KOMBI=`cat $KOMBI`; fi

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
  sed 's/<\/svg>/\n&/g'                  | # CLOSE TAG ON SEPARATE LINE
  sed "s/^[ \t]*//"                      | # REMOVE LEADING BLANKS
  tr -s ' '                              | # REMOVE CONSECUTIVE BLANKS
  tee > ${SVG%%.*}.tmp                     # WRITE TO TEMPORARY FILE
# --------------------------------------------------------------------------- #

  if [ "$INPUTKOMBI" != "YES" ];then 
# --------------------------------------------------------------------------- #
# CHOOSE LAYERS THAT ALLOW INPUT (OR NOT)
# --------------------------------------------------------------------------- #
  LAYERS2INPUT=`grep "$FOO" ${SVG%%.*}.tmp         | #
                sed '/^<g/s/>/&\n/g'               | # FIRST '>' ON NEWLINE
                grep ':groupmode="layer"'          | #
                sed '/^<g/s/scape:label/\nlabel/'  | #
                grep ^label                        | #
                grep -v "XX_"                      | # IGNORE XXCLUDED LAYERS
                cut -d "\"" -f 2`

  if [ "$INPUTTXT" == "YES" ];then 
        for INPUT in `grep -n 'charsallowed="' ${SVG%%.*}.tmp | #
                      cut -d ":" -f 1`
         do 
            CHARSALLOWED=`sed -n "${INPUT}p" ${SVG%%.*}.tmp | #
                          sed 's/charsallowed=/\n&/g' | #
                          grep -n '^charsallowed="' | cut -d "\"" -f 2`
            if [ "$CHARSALLOWED" -ge "$CHARSNEEDED" ]; then
                  LAYERNAME=`sed -n "${INPUT}p" ${SVG%%.*}.tmp | #
                             sed 's/scape:label/\nlabel/g' | #
                             grep -v "XX_" | #
                             grep -n '^label' | cut -d "\"" -f 2`
                  INPUTHERE="$INPUTHERE $LAYERNAME"
            fi
        done
        INPUTHERE=`echo $INPUTHERE | # ALL POSSIBLE
                   sed 's/ /\n/g'  | # SEPARATE ON LINES
                   shuf -n 1 `       # SELECT ONE
        DONOTINPUTHERE=`echo $LAYERS2INPUT |  # ALL INPUTS
                        sed 's/ /\n/g'     |  # SEPARATE ON LINES
                        grep -v "$INPUTHERE"` # RM SELECTED INPUT
        DONOTINPUTHERE=`echo $DONOTINPUTHERE | sed 's/ /|/g'`
        INPUTFILTER="egrep \"$INPUTHERE\" | egrep -v \"$DONOTINPUTHERE\"";
        FLIP=""
   else 
        DONOTINPUTHERE=`echo $LAYERS2INPUT | sed 's/ /|/g'`
        INPUTFILTER="egrep -v \"$DONOTINPUTHERE\"";
        FLIP=" transform=\"scale(-1,1) translate(-$SVGWIDTH,0)\""
  fi

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
       ADDINPUTLAYERS=`echo $LAYERS2INPUT | # 
                       sed 's/ /\n/g'     | #
                       grep $BASETYPE`      #
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

# --------------------------------------------------------------------------- #
# WRITE SVG FILES ACCORDING TO POSSIBLE COMBINATIONS
# --------------------------------------------------------------------------- #
  SVGHEADER=`head -n 1 ${SVG%%.*}.tmp`   

  for KOMBI in `cat $KOMBILIST               | # USELESS USE OF CAT
                eval $INPUTFILTER | #
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
     #shuf -n 2 --random-source=<(mkseed $NAME) | # SELECT (NOT SO) RANDOM
      sed 's/display:inline/display:none/g'       > ${SVGOUT}.tmp

      head -n 1 ${SVG%%.*}.tmp                           >  $SVGOUT
      for  LAYERNAME in `echo $KOMBI`
        do grep -n "label=\"$LAYERNAME\"" ${SVG%%.*}.tmp >> ${SVGOUT}.tmp
      done
      cat ${SVGOUT}.tmp | sort -n | cut -d ":" -f 2-     >> $SVGOUT
      echo "</svg>"                                      >> $SVGOUT
      rm ${SVGOUT}.tmp

      INJECT=`echo "$NOISE"          | # ASSUMED UTF-8
              sed "s/&/\\\\\&amp;/g" | #
              sed "s/\"/\\\\\"/g"`     #
      LN=`grep -n $FOO $SVGOUT | cut -d ":" -f 1 | tail -n 1`

      sed -i "${LN}s/$FOO/$INJECT/g" $SVGOUT
      sed -i "s/$FOO//g" $SVGOUT

      if [ `seq 1 100 | #
            shuf -n 1 --random-source=<(mkseed $NAME)` -gt 50 ]
      then sed -i "s/groupmode=\"layer\"/&$FLIP/g" $SVGOUT ; fi

           DONE="YES"
      else
           sleep 0; # echo "$SVGOUT exists"
      fi

      fi
  done
# --------------------------------------------------------------------------- #
  else
       NAME=`echo $KOMBI$NOISE | md5sum | #
             cut -d " " -f 1 | cut -c 1-12 | #
             sed 's/.$/K/' | tr [:lower:] [:upper:]`
      SVGOUT=$OUTDIR/B${NAME}.svg

      echo "KOMBI PROVIDED"
      echo "WRITING: $SVGOUT"

      grep -n 'label="XX_DEKO' ${SVG%%.*}.tmp   | #
      sed 's/display:inline/display:none/g'       > ${SVGOUT}.tmp

      head -n 1 ${SVG%%.*}.tmp                           >  $SVGOUT
      for  LAYERNAME in `echo $KOMBI`
        do grep -n "label=\"$LAYERNAME\"" ${SVG%%.*}.tmp >> ${SVGOUT}.tmp
      done
      cat ${SVGOUT}.tmp | sort -n | cut -d ":" -f 2-     >> $SVGOUT
      echo "</svg>"                                      >> $SVGOUT
      rm ${SVGOUT}.tmp

      CHARCNT=`echo "$NOISE" | wc -c`

      if   [ $CHARCNT -le  5 ];then FONTSIZE=90
      elif [ $CHARCNT -le 15 ];then FONTSIZE=60
      elif [ $CHARCNT -lt 35 ];then FONTSIZE=40
      elif [ $CHARCNT -lt 70 ];then FONTSIZE=30
      else   FONTSIZE=20; fi

      INJECT=`echo "$NOISE"          | # ASSUMED UTF-8
              sed "s/&/\\\\\&amp;/g" | #
              sed "s/\"/\\\\\"/g"`     #
      LN=`grep -n $FOO $SVGOUT | cut -d ":" -f 1 | tail -n 1`

      sed -i "${LN}s/$FOO/$INJECT/g" $SVGOUT
      sed -i "s/$FOO//g" $SVGOUT
      sed -i "s/font-size:[0-9pxt;]*/font-size:${FONTSIZE};/g" $SVGOUT
  fi
# --------------------------------------------------------------------------- #
# REMOVE TEMP FILES
# --------------------------------------------------------------------------- #
  rm ${SVG%%.*}.tmp $KOMBILIST
# =========================================================================== #

exit 0;

