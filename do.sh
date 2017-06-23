#!/bin/bash

# --------------------------------------------------------------------------- #
# CONFIGURE.
# --------------------------------------------------------------------------- #
  OUTPUTDIR="_";BASEURL="http://freeze.sh" # USED FOR REDIRECT
  MENTIONDUMP=$OUTPUTDIR/dump.mentions
  TMP="XXTMP"`date +%s` # PREFIX TO IDENTIFY TMP FILES
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
  source lib/sh/network.functions
# --------------------------------------------------------------------------- #
# FOR THE LOG
# --------------------------------------------------------------------------- #
  echo -e "--------------------------\nSTART: "`date "+%d.%m.%Y %H:%M:%S"`
# --------------------------------------------------------------------------- #
# CHECK CONNECTIVITY
# --------------------------------------------------------------------------- #
  checkConnection lafkon.net twitter.com 
# --------------------------------------------------------------------------- #
# FIRST THINGS FIRST
# --------------------------------------------------------------------------- #
  if [ `echo "$*" | wc -c` -le 1 ]; then
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

         MENTION=`sed '/./{H;d;};x;s/\n/={NL}=/g' $MENTIONDUMP | #
                  grep -- "$IDUNDONE"`

         MESSAGE=`echo $MENTION               | #
                  sed 's/={NL}=/\n/g'         | #
                  grep -v "^-.*\{5,\}$"       | #
                  sed '/^[ ]*$/d'             | #
                  head -n 1                   | #
                  recode h0..utf8             | # DEAL WITH &amp; &gt; (?)
                  ascii2uni -a U -q           | # CONVERT TO UNICODE
                  recode utf8..h0             | # CONVERT TO HTML (TO IDENTIFY)
                  sed 's/\&#[0-9]\{5,\};/-/g' | # REMOVE RANGE (+5)
                  recode h0..utf8`              # BACK TO UTF-8
         MESSAGE=`echo -e "$MESSAGE "                | # START WITH TEXT
                  sed 's/^@makebotbot[^a-zA-Z0-9]//' | #
                  sed 's/^.*@makebotbot://g'         | #
                  sed 's/^[ \t]*//'                  | # REMOVE LEADING BLANKS
                  sed 's/[ \t]$//'`                    # REMOVE CLOSING BLANKS

             MID=`echo $MENTION         | #
                  sed 's/={NL}=/\n/g'   | #
                  grep -v "^-.*\{5,\}$" | #
                  sed '/^[ ]*$/d'       | #
                  head -n 2 | tail -n 1`  #
           MFROM=`echo $MENTION         | #
                  sed 's/={NL}=/\n/g'   | #
                  grep -v "^-.*\{5,\}$" | #
                  sed '/^[ ]*$/d'       | #
                  head -n 3 | tail -n 1`  #
           MFROM=`echo @$MFROM | sed 's/@makebotbot/makebotbot/g'`

         ANOTHEROUTPUT=`./mk.sh "$MESSAGE" | cut -d ":" -f 2`
         if [ -f $ANOTHEROUTPUT ]; then
             THISTWEET=`echo "$ANOTHEROUTPUT" | sed 's/ /\n/g' | #
                        tail -n 1 | sed 's/\.svg$//'`TWEET.txt
             THISANCHOR=`basename "$THISTWEET"       | #
                         sed 's/TWEET\.txt$//'       | # 
                         cut -c 1-8 | sed 's/^B/bt/' | #
                         tr [:upper:] [:lower:]`       #
            #THISMESSAGE="$MFROM →  $BASEURL/$THISANCHOR -r=$MID"
             THISMESSAGE="$BASEURL/$THISANCHOR made for $MFROM -r=$MID"
             echo "$THISMESSAGE" > $THISTWEET
       # -------------------------------------------------------------- #
       # MARK AS DONE
       # -------------------------------------------------------------- #
             sed -i "s/^\(-\)\($IDORIGINAL\)/-XX\2/" $MENTIONDUMP

             OUTPUT="$OUTPUT $ANOTHEROUTPUT"
         fi

    done
         if [ -f ${TMP}.log ];then cat ${TMP}.log; rm ${TMP}.log ;fi
  else
# --------------------------------------------------------------------------- #
#  OTHERWISE: BE SELF-RELIANT
# --------------------------------------------------------------------------- #
    if [ "$HASINPUT" != "YES" ] && [ $((RANDOM%10)) -gt 5 ];then
  # ============================================================ #
  # GET OPTIONAL TEXT INPUT                                      #
  # ============================================================ #
    BOTPIT="http://freeze.sh/_/2017/botpit/show"
    BPDUMP="$OUTPUTDIR/plus.txt"
  # ------------------------------------------------------------ #
  # APPEND ONLINE SOURCE TO LOCAL DUMP
  # ------------------------------------------------------------ #
    (IFS=$'\n'; for ENTRY in `curl -sS $BOTPIT`;do
     MD5=`echo $ENTRY | md5sum | cut -d " " -f 1` #
     echo "$MD5:$ENTRY" >> $BPDUMP ; done; )
  # ------------------------------------------------------------ #
  # COPY 'MARKED AS DONE'
  # ------------------------------------------------------------ #
    for MD5 in `grep "^XX:[0-9a-f]*:" $BPDUMP | cut -d ":" -f 2`
    do sed -i "s/^${MD5}/XX:&/" $BPDUMP; done
  # ------------------------------------------------------------ #
  # SORT/UNIQ (IN PLACE)
  # ------------------------------------------------------------ #
    sort -u -o $BPDUMP $BPDUMP
  # ------------------------------------------------------------ #
  # SELECT RANDOM LINE (IF NOT 'MARKED AS DONE')
  # ------------------------------------------------------------ #
    SELECT=`grep -v "^XX:" $BPDUMP      | #
            sed 's,http.\?://[^ ]* ,,g' | # REMOVE URLS
            awk '{print NF ":" $0}'     | # PRINT WORD NUMBER
            grep -v "^[0123]:"          | # PRINT ONLY > 4
            cut -d ":" -f 2             | #
            shuf -n 1`                    # SELECT RANDOM (ONE)
  # ------------------------------------------------------------ #
  # GET CONTENT AND MARK AS DONE (IF SOMETHING'S THERE)
  # ------------------------------------------------------------ #
    if [ `echo $SELECT | wc -c` -gt 1 ]; then
          NOISE=`grep $SELECT $BPDUMP        | #
                 cut -d ":" -f 2-            | #
                 tr -s ' '                   | # SQUEEZE SPACES
                 sed 's,http.\?://[^ ]* ,,g' | # REMOVE URLS
                 sed 's/[ ,]*$//g'`            # RM THINGS AT THE END
        # ---------------------------------------------- #
        # MARK AS DONE
        # ---------------------------------------------- #
          sed -i "s/^$SELECT/XX:&/" $BPDUMP        
        # ---------------------------------------------- #
     else NOISE=""
    fi
  # ------------------------------------------------------------ #
    fi

    OUTPUT=`./mk.sh "$NOISE" | cut -d ":" -f 2`
    if [ -f $OUTPUT ]; then
        THISTWEET=`echo "$OUTPUT" | sed 's/ /\n/g' | #
                   tail -n 1 | sed 's/\.svg$//'`TWEET.txt
        THISANCHOR=`basename "$THISTWEET"       | #
                    sed 's/TWEET\.txt$//'       | #
                    cut -c 1-8 | sed 's/^B/bt/' | #
                    tr [:upper:] [:lower:]`       #
        if [ "$HASINPUT" == "YES" ];then
              THISMESSAGE="$NOISE →  $BASEURL/$THISANCHOR"
        else  THISMESSAGE="$BASEURL/$THISANCHOR"; fi
        echo "$THISMESSAGE" > $THISTWEET
    fi
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
          TWITTERUPLOAD=${O%%.*}TWEET.png 

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
                  GIF=$OUTPUTDIR/${NAME}.gif
          inkscape --export-png=${TMP}.png      \
                   --export-background-opacity=0 \
                   ${TMP}.svg > /dev/null 2>&1
               convert ${TMP}.png $IMG

   # ===================================================================== #
   # 2-BITISH THUMB
   # ===================================================================== #
     cp ${TMP}.svg ${TMP}2.svg
     CANVAS='<path style="fill:#ccffaa;" \
              d="m 0\,0 800\,0 0\,650 -800\,0 z" id="c" />'
     TRANSFORM='transform="scale(0.5\,0.5)"'
     sed -i 's/height="[0-9]*"/height="325"/g'        ${TMP}2.svg
     sed -i 's/width="[0-9]*"/width="400"/g'          ${TMP}2.svg
     sed -i "s,</metadata>,&<g $TRANSFORM>$CANVAS,g"  ${TMP}2.svg
     sed -i 's,</svg>,</g>&,g'                        ${TMP}2.svg
     sed -i 's/stroke-width:[0-9.]*/stroke-width:2/g' ${TMP}2.svg

     COUNT=0
     for COLOR in `sed 's/style="/\nS/g' ${TMP}2.svg | sed 's/"/\n/g' | #
                   grep "^S" | sed 's/#[0-9a-f]\{6\}/\n&\n/g'  | #
                   grep "^#" | sort -u`
      do
         sed -re "s/$COLOR/XxXxXx/g" ${TMP}2.svg  |  # PROTECT COLOR
         sed -re 's/#[0-9A-Fa-f]{6}/#ffffff/g'   |  # ALL HEX TO WHITE
         sed -re "s/XxXxXx/#000000/g" > ${TMP}3.svg # UNPROTECT TO BLACK
         inkscape --export-pdf=${TMP}.pdf ${TMP}3.svg
         convert -monochrome -flatten ${TMP}.pdf ${TMP}.gif
         convert ${TMP}.gif -fill $COLOR -opaque black ${COUNT}.gif
         if [ $COUNT -gt 0 ]; then
         composite -compose Multiply -gravity center \
                    collect.gif ${COUNT}.gif ${TMP}.gif
              mv ${TMP}.gif collect.gif;rm ${COUNT}.gif
         else mv ${COUNT}.gif collect.gif;rm ${TMP}.gif
         fi;  COUNT=`expr $COUNT + 1`
     done
     convert collect.gif -fill $C1 -opaque black ${TMP}.gif
     convert ${TMP}.gif -transparent "#ccffaa" $GIF
     rm ${TMP}2.svg ${TMP}3.svg ${TMP}.pdf collect.gif ${TMP}.gif
   # ===================================================================== #

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
     HTMLELEMENT=`echo "<figure id=\"$ANCHOR\">
                        <a href=\"$HREF\" target=\"_blank\">
                        <img src=\"../_/32x26.gif\"
                         data-src=\"$NAME.gif\" class=\"unveil\"/>
                        <noscript><img src=\"$NAME.gif\"/></noscript>
                        </a><figcaption>
                        <a href=\"$HREFSVG\"><span class=\"l\">svg</span></a>
                        <a href=\"$HREFPDF\"><span class=\"r\">pdf</span></a>
                        </figcaption></figure>"`
          HTMLADD="${HTMLADD}={NL}=${HTMLELEMENT}"
          FTPCOLLECT="$FTPCOLLECT $O $PDF $IMG $GIF"

         else
               echo "SOMETHING WENT WRONG"
               echo "$OUTPUT"
      fi
  done

# --------------------------------------------------------------------------- #
# UPDATE FREEZE.SH
# --------------------------------------------------------------------------- #

  if [ `ls $OUTPUTDIR/*.* 2> /dev/null | #
        grep "TWEET.txt$" | wc -l` -gt 0 ]; then

  ADDHERE="^<!-- = INJECT HERE =* -->$"

  # ----------------------------------------------------------------------- #
  # GET/UPDATE HTML
  # ----------------------------------------------------------------------- #
  ( IFS=$'\n'
    for ELEMENT in `echo $HTMLADD       | #
                    sed 's/={NL}=/\n/g' | #
                    tr -s ' '           | #
                    sed 's/>[ ]*</></g'`  #
     do
        ID=`echo $ELEMENT | sed 's/id=/\n&/' | #
            grep "^id=" | cut -d "\"" -f 2`
        HTMLNAME=`echo $ID | cut -c 2`
        HTMLREMOTE="http://freeze.sh/_/2017/socialbots/o/$HTMLNAME.html"
        HTMLTMP="${TMP}.$HTMLNAME.REMOTE.html"
        if [ ! -f $HTMLTMP ]; then
             wget --no-check-certificate \
                  -O $HTMLTMP             \
                  $HTMLREMOTE > /dev/null 2>&1
        fi
        sed -i "s,${ADDHERE},&\n\n${ELEMENT},g" $HTMLTMP
   done ;)

    for HTMLTMP in `ls *.* | grep "${TMP}\..\.REMOTE.html"`
     do
        HTMLUPDATE=`echo $HTMLTMP     | #
                    sed "s/${TMP}.//" | #
                    cut -d "." -f 1`.html
        mv $HTMLTMP $HTMLUPDATE
        HTMLNEW="$HTMLNEW $HTMLUPDATE"
    done
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
           NAME=`basename $T | cut -d "." -f 1 | sed 's/TWEET$//'`
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

  fi

# --------------------------------------------------------------------------- #
# CLEAN UP / RM TEMPORARY FILES
# --------------------------------------------------------------------------- #
  for HTMLUPDATE in `echo $HTMLNEW`;do
  if [ -f $HTMLUPDATE        ];then rm $HTMLUPDATE                  ;fi; done
  if [ -f ${TMP}.png         ];then rm ${TMP}.png                     ;fi
  if [ -f ${TMP}.svg         ];then rm ${TMP}.svg                       ;fi
  if [ -f ${TMP}.REMOTE.html ];then rm ${TMP}.REMOTE.html                 ;fi

# --------------------------------------------------------------------------- #
# FOR THE LOG
# --------------------------------------------------------------------------- #
  echo -e "READY: "`date "+%d.%m.%Y %H:%M:%S"`"\n--------------------------\n"


exit 0;
