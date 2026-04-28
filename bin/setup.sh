#!/bin/bash
#
# PATHS
nbp_Base=~/dev/newbashplot
nbp_Bin=${nbp_Base}/bin
nbp_Cfg=${nbp_Base}/cfg
nbp_Data=${nbp_Base}/data

# Global constants
typeset -i nbp_caaX=0 nbp_caaY=0 nbp_paaX=0 nbp_paaY=0 nbp_vbiX=0 nbp_vbiY=0 nbp_vbi=0 nbp_oldVbi=0 nbp_codePoint=0
typeset -i nbp_widthBraille=2 nbp_heightBraille=4

typeset -i nbp_CAAW=$(tput cols)
typeset -i nbp_CAAH=$(tput lines)

typeset -i nbp_PAAW=$((nbp_CAAW*nbp_widthBraille))
typeset -i nbp_PAAH=$((nbp_CAAH*nbp_heightBraille))

typeset -i nbp_CBC=${nbp_widthBraille}		# Character Block Columns
typeset -i nbp_CBR=${nbp_heightBraille}		# Character Block Rows

# Global variables
nbp_displayPlot=""

# Global associative/ 2D arrays
# nbp_CAAV is the Cursor Addressable Area for Virtual Bitmask
# nbp_CAAC is the Cursor Addressable Area for Characters
# nbp_tputCUP is a cache for tput row and column control codes
declare -A nbp_CAAV nbp_CAAC nbp_tputCUP

# Configuration Files
source ${nbp_virtualBitmap:=${nbp_Cfg}/VROBI-braille.cfg}
source ${nbp_codePoints:=${nbp_Cfg}/UnicodeCodePoint-x2800-x100-x28ff.cfg}


source ${nbp_Bin}/functions.sh


