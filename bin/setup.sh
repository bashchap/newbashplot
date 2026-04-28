#!/bin/bash
#
# PATHS
Base=~/dev/newbashplot
Bin=${Base}/bin
Cfg=${Base}/cfg
Data=${Base}/data

# Global constants
typeset -i caaX=0 caaY=0 paaX=0 paaY=0 vbiX=0 vbiY=0 vbi=0 oldVbi=0 codePoint=0
typeset -i widthBraille=2 heightBraille=4

typeset -i PAAW=160 PAAH=96
typeset -i CAAW=PAAW/widthBraille
typeset -i CAAH=PAAH/heightBraille

typeset -i CBC=${widthBraille}		# Character Block Columns
typeset -i CBR=${heightBraille}		# Character Block Rows

# Global variables
displayPlot=""

# Global associative/ 2D arrays
# CAAV is the Cursor Addressable Area for Virtual Bitmask
# CAAC is the Cursor Addressable Area for Characters
# tputCUP is a cache for tput row and column control codes
declare -A CAAV CAAC tputCUP

# Configuration Files
source ${VirtualBitmap:=${Cfg}/VROBI-braille.cfg}
source ${CodePoints:=${Cfg}/UnicodeCodePoint-x2800-x100-x28ff.cfg}


source ${Bin}/functions.sh


