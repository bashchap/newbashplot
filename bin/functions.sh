#!/bin/bash

_f_Log() {
echo "_f_Plot_paaX=$_f_Plot_paaX"
echo "_f_Plot_paaY=$_f_Plot_paaY"
echo "caaX=$caaX"
echo "caaY=$caaY"
echo "vbiX=$vbiX"
echo "vbiY=$vbiY"
echo "vbi=$vbi"
echo "codePoint=$codePoint"
}

# Plot a pixel:
# Take Pixel Addressable Area (PAA) coordinate and convert to 
# Cursor Addressable Area (CAA) coordinate and then
# determine which bit in font is being addressed at that CAA.
# Add that pixel, or if 3rd parameter is supplied (off) then turn
# that pixel off
_f_Plot() {
typeset -i _f_Plot_paaX=${1?"ERROR"}
typeset -i _f_Plot_paaY=${2?"ERROR"}
_f_Plot_OPT=${3}
codePoint=0

# Calculate Cursor Addressable Area coordinates
# Take into consideration the number of pixels horizontally and vertically
caaX=_f_Plot_paaX/CBC
caaY=_f_Plot_paaY/CBR

# Calculate Virtual Bit Index coordinates (which pixel in a character block)
vbiX=_f_Plot_paaX%CBC
vbiY=_f_Plot_paaY%CBR

# Calculate Virtual Bitmap Index from vbiX/Y
vbi=$(((2**vbiY)<<(vbiX*CBR)))

# Retrieve the vbi at the current caa, default to 0 if never set
oldVbi=${CAAV[${caaX},${caaY}]:=0}

# If the option to turn the pixel off has been selected...
  if [ "${_f_Plot_OPT}" = "off" ]
  then
	  vbi=$(((vbi^255)&oldVbi)) # Turn off the specified pixel
  else
          vbi=$((vbi|oldVbi))	# Bitwise OR the calculated bit with the existing bits at the same CAA
  fi

# Store the newly calculated VBI.
CAAV[${caaX},${caaY}]=${vbi}
# Store the associated unicode character after index translation
unicodeChar="${uCodePoint[${VROBI[${vbi}]}]}"
CAAC[${caaX},${caaY}]="${unicodeChar}"
# If the system-wide variable displPlot is set, output the plot NOW.
  if [ ! -z "${displayPlot}" ]
  then
	  echo "${tputCUP[${caaY},${caaX}]:=$(tput cup ${caaY} ${caaX})}${unicodeChar}"
  fi
}

# Output the plot
_f_Show() {
	typeset -i x=0 y=0
	while [ $y -lt $CAAH ]
	do
		x=0
		while [ $x -lt $CAAW ]
		do
			echo -n "${CAAC[${x},${y}]:-" "}"
			let x=x+1
		done
  	  let y=y+1
	  echo	
        done
}
