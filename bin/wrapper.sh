#!/bin/bash

# This source line MUST be the first line of any bash code the functions are used in, otherwise the $_
# parameter will notr be set accordingly and relative paths will not be set either
source ~/dev/newbashplot/bin/setup.sh
nbp_displayPlot=yes
tput civis

typeset -i h=0 w=0 
typeset -i xPos=0 yPos=0

typeset -i xV=$(($nbp_PAAW/2))
typeset -i yV=$(($nbp_PAAH/2))
typeset -i dX=0 dY=0 dN=0 dNC=0 dNMax=400
typeset -i maxLength=40
typeset -i minLength=20
typeset -i xVM yVM

clear

SECONDS=0
  while :
  do
      [ $((${xV}+${dX})) -lt 0 -o $((${xV}+${dX})) -ge $((${nbp_PAAW})) ] && dX=$((-${dX}))
      [ $((${yV}+${dY})) -lt 0 -o $((${yV}+${dY})) -ge $((${nbp_PAAH})) ] && dY=$((-${dY}))
    xV+=dX yV+=dY
      if [ ${dN} -lt 1 ]
      then
        dX=$((1-($RANDOM%3)))
        dY=$((1-($RANDOM%3)))
          [ ${dX} -eq 0 -a ${dY} -eq 0 ] && continue
	  dN=$((($RANDOM%(${maxLength})+(${minLength})+1)))
        dNC+=1
         if [ ${SECONDS} -gt 10 ]
         then
           maxLength=$((($RANDOM%100)+1))
           minLength=$((($RANDOM%10)+1))

# Need to clear the CAA* arrays
  	     for key in "${!nbp_CAAV[@]}"; do unset "nbp_CAAV[$key]" ; done
  	     for key in "${!nbp_CAAC[@]}"; do unset "nbp_CAAC[$key]" ; done

           clear
           SECONDS=0
         fi
      fi

# This is the plotting activity
# xV and yV are coordinates in the virual space and are used to calculate
# the bloxel required...

# ...and also used to map to physical coordinates

    let xVM=$nbp_PAAW-${xV}
    let yVM=$nbp_PAAH-${yV}
    nbp_f_Plot $xV $yV
    nbp_f_Plot $xVM $yV
    nbp_f_Plot $xV $yVM
    nbp_f_Plot $xVM $yVM
    
    dN=$(($dN-1))
#sleep 0.1
  done

