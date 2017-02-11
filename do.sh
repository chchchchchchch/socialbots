#!/bin/bash

# --------------------------------------------------------------------------- #
# CONFIGURE.
# --------------------------------------------------------------------------- #
  OUTPUTDIR="_";BASEURL="http://freeze.sh" # USED FOR REDIRECT
  MENTIONDUMP=$OUTPUTDIR/dump.mentions
  TMP=XXTMP # PATTERN TO IDENTIFY TMP FILES
# --------------------------------------------------------------------------- #
# CONFIGURE YOURSELF
# --------------------------------------------------------------------------- #
  PROJEKTROOT=`readlink -f $0   | # DISPLAY ABSOLUTE PATH
               rev              | # REVERT (LAST BECOMES FIRST)
               cut -d "/" -f 2- | # REMOVE FIRST FIELD
               rev`               # REVERT BACK AGAIN
  cd $PROJEKTROOT
# --------------------------------------------------------------------------- #
# INCLUDE.
# --------------------------------------------------------------------------- #
  source lib/sh/twitter.functions
  source lib/sh/ftp.functions
  source lib/sh/shuffle.functions
 #source lib/sh/network.functions # TODO!

# --------------------------------------------------------------------------- #
# FOR THE LOG
# --------------------------------------------------------------------------- #
  echo -e "--------------------------\nSTART: "`date "+%d.%m.%Y %H:%M:%S"`
# --------------------------------------------------------------------------- #
# FIRST THINGS FIRST
# --------------------------------------------------------------------------- #
  if [ `echo $* | wc -c` -le 1 ]; then
       HASINPUT="NO"  ; NOISE=""
  else HASINPUT="YES" ; NOISE=`echo "$*" | sed 's/^[ ]*//'`; fi

# --------------------------------------------------------------------------- #
# CHECK TIME
# --------------------------------------------------------------------------- #
  MINUTE=`date +%M | sed 's/^[0-9]//'`

  if [ "$HASINPUT" != "YES" ] &&
     [ "$MINUTE"   != "0"   ] && [ "$MINUTE"   != "5" ]; then

# --------------------------------------------------------------------------- #
  echo "-> CHECK MENTIONS" #  CHECK/COLLECT IF THERE'S ANTYTHING TO REPLY TO  #
# --------------------------------------------------------------------------- #

  # GET MENTIONS INFO FROM TWITTER (+APPEND TO DUMP)
  # --------------------------------------------------------------------- # 
    getMentions >> $MENTIONDUMP

  # --------------------------------------------------------------------- #
  # FIND IDs MARKED AS DONE
  # --------------------------------------------------------------------- # 
    for IDDONE in `grep "^-XX[0-9]\{18\}" $MENTIONDUMP`
     do
      IDORIGINAL=`echo $IDDONE      | # DISPLAY ID
                  sed 's/[^0-9]*//g'` # RM ALL BUT NUMBERS
    # ----------------------------------------------------------------- #
    # MARKED SAME IDs (IF UNMARKED) AS DONE
    # ----------------------------------------------------------------- #
      sed -i "s/^\(-\)\($IDORIGINAL\)/-XX\2/" $MENTIONDUMP
    done
  # --------------------------------------------------------------------- #
  # CLEAN UP DUMP (REMOVE DUPLICATES PARAGRAPHS)
  # --------------------------------------------------------------------- #
    sed '/./{H;d;};x;s/\n/={NL}=/g' $MENTIONDUMP | #
    sort -u | sed '1s/={NL}=//;s/={NL}=/\n/g' > ${TMP}.mentions
    mv ${TMP}.mentions $MENTIONDUMP ; echo >> $MENTIONDUMP
  # --------------------------------------------------------------------- # 
  # CHECK UNDONE MENTIONS
  # --------------------------------------------------------------------- # 
    for IDUNDONE in `grep "^-[0-9]\{18\}" $MENTIONDUMP`
      do
         IDORIGINAL=`echo $IDUNDONE | # DISPLAY ID
                  sed 's/[^0-9]*//g'` # RM ALL BUT NUMBERS

        #sed '/./{H;d;};x;s/\n/={NL}=/g' $MENTIONDUMP | #
        #grep -- "$IDUNDONE" | #
        #sed '1s/={NL}=//;s/={NL}=/\n/g'

         MENTION=`sed '/./{H;d;};x;s/\n/={NL}=/g' $MENTIONDUMP | #
                  grep -- "$IDUNDONE"`

         MESSAGE=`echo $MENTION             | #
                  sed 's/={NL}=/\n/g'       | #
                  grep -v "^-.*\{5,\}$"     | #
                  sed '/^[ ]*$/d'           | #
                  head -n 1                 | #
                  sed 's/\\\\\\u.\{4\}/-/g' | # RM (EMOJI) CRAP
                  recode h0..utf-8`           #
         MESSAGE=`echo -e "$MESSAGE "   | # START WITH TEXT
                  sed 's/^@makebotbot[^a-zA-Z0-9]//'  | #
                  sed 's/^.*@makebotbot://g' | #
                  sed 's/^[ \t]*//'     | # REMOVE LEADING BLANKS
                  sed 's/[ \t]$//'`       # REMOVE CLOSING BLANKS

             MID=`echo $MENTION | #
                  sed 's/={NL}=/\n/g' | #
                  grep -v "^-.*\{5,\}$" |#
                  sed '/^[ ]*$/d' | head -n 2 | tail -n 1`
           MFROM=`echo $MENTION | #
                  sed 's/={NL}=/\n/g' | #
                  grep -v "^-.*\{5,\}$" |#
                  sed '/^[ ]*$/d' | head -n 3 | tail -n 1`

         OUTPUT="$OUTPUT "`./mk.sh "$MESSAGE" | cut -d ":" -f 2`
         THISTWEET=`echo $OUTPUT | sed 's/ /\n/g' | #
                    tail -n 1 | sed 's/\.svg$//'`-TWEET.txt
         THISANCHOR=`basename $THISTWEET         | #
                     sed 's/-TWEET\.txt$//'      | # 
                     cut -c 1-8 | sed 's/^B/bt/' | #
                     tr [:upper:] [:lower:]`       #

         THISMESSAGE="@$MFROM →  $BASEURL/$THISANCHOR -r=$MID"
         echo "$THISMESSAGE" > $THISTWEET

       # -------------------------------------------------------------- #
       # MARK AS DONE
       # -------------------------------------------------------------- #
         sed -i "s/^\(-\)\($IDORIGINAL\)/-XX\2/" $MENTIONDUMP
    done
         if [ -f ${TMP}.log ];then cat ${TMP}.log; rm ${TMP}.log ;fi
  else
# --------------------------------------------------------------------------- #
#  OTHERWISE: BE SELF-RELIANT
# --------------------------------------------------------------------------- #

     OUTPUT=`./mk.sh "$NOISE" | cut -d ":" -f 2`
     THISTWEET=`echo $OUTPUT | sed 's/ /\n/g' | #
                tail -n 1 | sed 's/\.svg$//'`-TWEET.txt
     THISANCHOR=`basename $THISTWEET         | #
                 sed 's/-TWEET\.txt$//'      | #
                 cut -c 1-8 | sed 's/^B/bt/' | #
                 tr [:upper:] [:lower:]`       #

     THISMESSAGE="$BASEURL/$THISANCHOR"
     echo "$THISMESSAGE" > $THISTWEET

  fi

# --------------------------------------------------------------------------- #
#  G O  F  U   R   T    H     E     R
# --------------------------------------------------------------------------- #
  for O in `echo $OUTPUT | sed 's/ /\n/g'`
   do
      if [ -f $O ]; then

          NAME=`basename $O | cut -d "." -f 1`
        # ================================================================ #
        # MAKE IMAGE FOR TWITTER
        # ================================================================ #
          TWITTERUPLOAD=${O%%.*}-TWEET.png 

         #C1="#ff0000";C2="#ff0000";BG="#ffffff"
          C1="#1b17cf";C2="#1b17cf";BG="#ffffff"
          sed 's/#[fF]\{6\}/XxXxXx/g' $O | #
          sed 's/stroke-width:[0-9.]*/stroke-width:2.5/g' | #
          sed "s/fill:#[0-9a-fA-F]\{6\}/fill:$C1/g" | #
          sed "s/stroke:#[0-9a-fA-F]\{6\}/stroke:$C2/g" | #
          sed "s/XxXxXx/$BG/g" | #
          tee > ${TMP}.svg

          for SHOWTHIS in `grep -n "show=\"twitter" ${TMP}.svg | #
          cut -d ":" -f 1 | shuf -n 2 --random-source=<(mkseed $NAME)`;do
          sed -i "${SHOWTHIS}s/splay:none/splay:inline/g" ${TMP}.svg;done
          inkscape --export-png=${TMP}.png      \
                   --export-background-opacity=0 \
                   ${TMP}.svg > /dev/null 2>&1
          convert ${TMP}.png -background "$BG" -flatten $TWITTERUPLOAD

        # ---------------------------------------------------------------- #
        # FORCE PNG ON TWITTER
        # ---------------------------------------------------------------- #
        # MAKE 1 PIXEL 99% OPAQUE (THIS REALLY SHOULD BE DONE DIFFERENT!)
        # ---------------------------------------------------------------- #
        # MAKE PIXEL FULL TRANSPARENT ------------------------------------ #
          convert $TWITTERUPLOAD -alpha on -fill none \
                               -draw 'color 0,0 point' ${TMP}.1.png
        # MAKE FULL IMAGE 99% OPAQUE ------------------------------------- #
          convert $TWITTERUPLOAD -alpha set -channel A \
                                 -evaluate set 99% ${TMP}.2.png
        # COMBINE -------------------------------------------------------- #
          composite -gravity center \
                    ${TMP}.1.png ${TMP}.2.png \
                    $TWITTERUPLOAD
        # CLEAN UP ------------------------------------------------------- #
          rm ${TMP}.1.png ${TMP}.2.png
        # ---------------------------------------------------------------- #
        # tweet $TWITTERUPLOAD

        # ================================================================ #
        # PREPARE UPLOAD FOR FREEZE
        # ================================================================ #
         #C1="#cf1717";C2="#cf1717";BG="#ffffff"
         #C1="#17cf17";C2="#17cf17";BG="#ffffff"
          C1="#1b17cf";C2="#1b17cf";BG="#ffffff"
          sed 's/#[fF]\{6\}/XxXxXx/g' $O | #
          sed 's/stroke-width:[0-9.]*/stroke-width:2.5/g' | #
          sed "s/fill:#[0-9a-fA-F]\{6\}/fill:$C1/g" | #
          sed "s/stroke:#[0-9a-fA-F]\{6\}/stroke:$C2/g" | #
          sed "s/XxXxXx/$BG/g" | #
          tee > ${TMP}.svg

                  IMG=$OUTPUTDIR/${NAME}.png
                  PDF=$OUTPUTDIR/${NAME}.pdf
          inkscape --export-png=${TMP}.png      \
                   --export-background-opacity=0 \
                   ${TMP}.svg > /dev/null 2>&1
               convert ${TMP}.png $IMG
          inkscape --export-pdf=${PDF}  \
                   --export-text-to-path \
                   $O > /dev/null 2>&1

               ANCHOR=`echo $NAME | #
                       cut -c 1-8 | #
                       tr [:upper:] [:lower:]`
               IMGSRC=`basename $IMG`
                 HREF="XX$NAME"
              HREFSVG="${NAME}.svg"
              HREFPDF="${NAME}.pdf"
          HTMLELEMENT=`echo "<table class=\"floin\" id=\"$ANCHOR\">
                       <tr><td colspan=\"2\"
                               class=\"px\">
                       <a href=\"$HREF\" target=\"_blank\">
                       <img src=\"$IMGSRC\"/></a>
                       </td></tr><tr><td class=\"t l\">
                       <a href=\"$HREFSVG\">SVG</a>
                       </td><td class="t r">
                       <a href=\"$HREFPDF\">PDF</a>
                       </td></tr></table>"`
          HTMLADD="${HTMLADD}={NL}=${HTMLELEMENT}"
          FTPCOLLECT="$FTPCOLLECT $O $PDF $IMG"

         else
               echo "SOMETHING WENT WRONG"
               echo "$OUTPUT"
      fi
  done

# --------------------------------------------------------------------------- #
# UPDATE FREEZE.SH
# --------------------------------------------------------------------------- #
  # ----------------------------------------------------------------------- #
  # GET/UPDATE HTML
  # ----------------------------------------------------------------------- #
    ADDHERE="^<!-- = INJECT HERE =* -->$"
    HTMLTMP=${TMP}.REMOTE.html
    HTMLREMOTE="http://freeze.sh/_/2017/socialbots/o/index.html"
    HTMLNEW=`basename $HTMLREMOTE`
    wget --no-check-certificate \
         -O $HTMLTMP             \
         $HTMLREMOTE > /dev/null 2>&1
    HTMLADD=`echo $HTMLADD | tr -s ' ' | #
             sed 's/^={NL}=//' | sed 's/>[ ]*</></g'`
    sed "s,${ADDHERE},${HTMLADD}\n\n&,g" $HTMLTMP | #
    sed 's/={NL}=/\n/g' > $HTMLNEW

  # ----------------------------------------------------------------------- #
  # UPLOAD FILES ONLY (+ TEMPORARY INDEX)
  # ----------------------------------------------------------------------- #
    ftpUpload $FTPCOLLECT $HTMLNEW

# --------------------------------------------------------------------------- #
# TWEET
# --------------------------------------------------------------------------- #
  for T in `ls $OUTPUTDIR/*.* | grep "TWEET.txt$"`
   do
      if [ -f $T ] && 
         [ -f ${T%%.*}.png ]
      then
           echo ""; WHEN=`date "+%d.%m.%Y %H:%M:%S"`
           echo "PROCESSING: $NAME (${WHEN})"
         # ----------------------------------------------------------- #
           tweet `cat $T` ${T%%.*}.png
         # ----------------------------------------------------------- #
           BASEURL="https://twitter.com/makebotbot/status"
           NAME=`basename $T | cut -d "." -f 1 | sed 's/-TWEET$//'`
           FOOHREF="XX${NAME}"
           NEWHREF="$BASEURL/$STATUSID"
           sed -i "s,$FOOHREF,$NEWHREF,g" $HTMLNEW
           rm $T ${T%%.*}.png
         # ----------------------------------------------------------- #
         # FOR THE LOG
         # ----------------------------------------------------------- #
           echo "-> $NEWHREF"
           if [ -f ${TMP}.log ];then cat ${TMP}.log; rm ${TMP}.log ;fi
         # ----------------------------------------------------------- #
      else
           echo "SOMETHING WENT WRONG($T); DID NOT TWEET"
      fi
  done

  # ----------------------------------------------------------------------- #
  # UPLOAD UPDATED INDEX (WITH STATUS IDs)
  # ----------------------------------------------------------------------- #
    ftpUpload $HTMLNEW

# --------------------------------------------------------------------------- #
# CLEAN UP / RM TEMPORARY FILES
# --------------------------------------------------------------------------- #
  if [ -f $HTMLNEW           ];then rm $HTMLNEW                           ;fi
  if [ -f ${TMP}.png         ];then rm ${TMP}.png                         ;fi
  if [ -f ${TMP}.svg         ];then rm ${TMP}.svg                         ;fi
  if [ -f ${TMP}.REMOTE.html ];then rm ${TMP}.REMOTE.html                 ;fi

# --------------------------------------------------------------------------- #
# FOR THE LOG
# --------------------------------------------------------------------------- #
  echo -e "READY: "`date "+%d.%m.%Y %H:%M:%S"`"\n--------------------------\n"


exit 0;
