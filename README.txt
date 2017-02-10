
   -----------------------
  | S O C I A L   B O T S | (GRAPHIC+SOFTWARE)
   -----------------------

  http://research.radical-openness.org/2017/social-bots
  http://www.freeze.sh/_/2017/socialbots




  ============================================================
   C O P Y R I G H T  (C)  2017 Christoph Haag
  ============================================================
  
   If not stated otherwise permission is granted to copy,
   distribute and/or modify these documents under the terms
   of any of the following licenses (LICENSES.txt)
   
   EXECUTABLE CODE:
   
   the GNU General Public License as published by the Free
   Software Foundation; either version 3 of the License,
   or (at your option) any later version.
   --
   http://www.gnu.org/licenses/gpl.txt
   
   
   THE REST:
   
   the GNU Free Documentation License, Version 1.2 or any later
   version published by the Free Software Foundation; with no
   Invariant Sections, no Front-Cover Texts, and no Back-Cover
   Texts. A copy of the license is included in the section
   entitled "GNU Free Documentation License".
   --
   http://www.gnu.org/licenses/fdl
   
   the Creative Commons Attribution-ShareAlike License; either
   version 3.0 of license or any later version.
   --
   http://creativecommons.org/licenses/by-sa/3.0
   
   
   
   These documents are distributed in the hope that it
   will  be useful, but WITHOUT ANY WARRANTY; without even
   the implied warranty of MERCHANTABILITY or FITNESS FOR
   A PARTICULAR PURPOSE. 
   
   Your fair use and other rights are not affected by the above.
   
   TRADEMARKS, QUOTED MATERIAL AND LINKED CONTENT
   IS COPYRIGHTED ACCORDING TO ITS RESPECTIVE OWNERS. 
  
   E N J O Y !

  ============================================================


  ------------------------------------------------------------
  F O N T S  U S E D
  ------------------------------------------------------------

  Space Mono: Made by Colophon Foundry. Paid by Google.
  ----------  http://github.com/googlefonts/spacemono

  Whois Mono: Made by Raphaël Bastide (raphaelbastide.com)
  ----------  http://fontain.org/whois-mono

  ------------------------------------------------------------
  H E L P F U L
  ------------------------------------------------------------

 # OUTPUT RANDOM TEXT
   ------------------
  NOISE=`fortune -n 120 -s | tr -s ' '`; echo $NOISE 

 # LIST FONTS USED IN $SVG
   -----------------------
  grep "style" $SVG | sed 's/font-family/\n&/g' | \
  sed 's/;/\n/' | grep "^font-family" | sort -u

 # TWITTER POLICY (BEWARE!)
   -------------- 
  https://dev.twitter.com/overview/terms/policy

