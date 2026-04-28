#!/bin/bash
#
# Remember getopts?
#
#
source ~/dev/newbashplot/bin/setup.sh

typeset -i x=0
displayPlot=Y
  for n in {0..160}
  do

# Pixel Addressable Area coordinates
      if (( (n/5) % 2 ))
      then
        _f_Plot ${n} ${n}
      else
        _f_Plot ${n} ${n} off
      fi
      
  done

  _f_Show
