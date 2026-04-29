#!/bin/bash

# Plot a pixel:
# Take Pixel Addressable Area (PAA) coordinate and convert to 
# Cursor Addressable Area (CAA) coordinate and then
# determine which bit in font is being addressed at that CAA.
# Add that pixel, or if 3rd parameter is supplied (off) then turn
# that pixel off
nbp_f_Plot() {
typeset -i nbp_f_Plot_paaX=${1?"ERROR"}
typeset -i nbp_f_Plot_paaY=${2?"ERROR"}
nbp_f_Plot_OPT=${3}
nbp_codePoint=0

# Calculate Cursor Addressable Area coordinates
# Take into consideration the number of pixels horizontally and vertically
nbp_caaX=nbp_f_Plot_paaX/nbp_CBC
nbp_caaY=nbp_f_Plot_paaY/nbp_CBR

# Calculate Virtual Bit Index coordinates (which pixel in a character block)
nbp_vbiX=nbp_f_Plot_paaX%nbp_CBC
nbp_vbiY=nbp_f_Plot_paaY%nbp_CBR

# Calculate Virtual Bitmap Index from vbiX/Y
nbp_vbi=$(((2**nbp_vbiY)<<(nbp_vbiX*nbp_CBR)))

# Retrieve the vbi at the current caa, default to 0 if never set
nbp_oldVbi=${nbp_CAAV[${nbp_caaX},${nbp_caaY}]:=0}

# If the option to turn the pixel off has been selected...
  if [ "${nbp_f_Plot_OPT}" = "off" ]
  then
	  nbp_vbi=$(((nbp_vbi^255)&nbp_oldVbi)) # Turn off the specified pixel
  else
          nbp_vbi=$((nbp_vbi|nbp_oldVbi))	# Bitwise OR the calculated bit with the existing bits at the same CAA
  fi

# Store the newly calculated VBI.
nbp_CAAV[${nbp_caaX},${nbp_caaY}]=${nbp_vbi}
# Store the associated unicode character after index translation
#nbp_unicodeChar="${nbp_uCodePoint[${nbp_VROBI[${nbp_vbi}]}]}"
nbp_vbi2char="${nbp_VROBI[${nbp_vbi}]}"
#echo "-$nbp_vbi--${nbp_vbi2char}---" ; return
nbp_CAAC[${nbp_caaX},${nbp_caaY}]="${nbp_vbi2char}"
#nbp_CAAC[${nbp_caaX},${nbp_caaY}]="${nbp_unicodeChar}"
# If the system-wide variable displPlot is set, output the plot NOW.
  if [ ! -z "${nbp_displayPlot}" ]
  then
#	  echo -n "${nbp_tputCUP[${nbp_caaY},${nbp_caaX}]:=$(tput cup ${nbp_caaY} ${nbp_caaX})}${nbp_unicodeChar}"
	  echo -n "${nbp_tputCUP[${nbp_caaY},${nbp_caaX}]:=$(tput cup ${nbp_caaY} ${nbp_caaX})}${nbp_vbi2char}"
  fi
}

# Output the plot
nbp_f_Show() {
	typeset -i nbp_x=0 nbp_y=0
	while [ $nbp_y -lt $nbp_CAAH ]
	do
		nbp_x=0
		while [ $nbp_x -lt $nbp_CAAW ]
		do
			echo -n "${nbp_CAAC[${nbp_x},${nbp_y}]:-" "}"
			let nbp_x=nbp_x+1
		done
  	  let nbp_y=nbp_y+1
	  echo	
        done
}
