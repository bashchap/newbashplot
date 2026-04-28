#!/bin/bash
#
# Remember getopts?
#
#
source ~/dev/newbashplot/bin/setup.sh

typeset -i nbp_n=0
nbp_displayPlot=Y
  for nbp_n in {0..160}
  do

# Pixel Addressable Area coordinates
      if (( (nbp_n/5) % 2 ))
      then
        nbp_f_Plot ${nbp_n} ${nbp_n}
      else
        nbp_f_Plot ${nbp_n} ${nbp_n} off
      fi
      
  done

nbp_f_Show
