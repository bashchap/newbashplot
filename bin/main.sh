#!/bin/bash
#
# Remember getopts?
#
#
source ~/dev/newbashplot/bin/setup.sh

typeset -i x=0

  for n in {0..95}
  do

# Pixel Addressable Area coordinates
     _f_Plot ${n} ${n}
  done


  _f_Show
