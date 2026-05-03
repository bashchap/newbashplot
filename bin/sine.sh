#!/bin/bash

# This source line MUST be the first line of any bash code the functions are used in, otherwise the $_
# parameter will not be set accordingly and relative paths will not be set either
source ~/dev/newbashplot/bin/setup.sh

nbp_displayPlot=yes

# turns off cursor
tput civis 

# tput cvvis turns on cursor
# Setup caculator co-process for maximum efficiency
coproc bc -l
calcOut=${COPROC[0]} calcIn=${COPROC[1]}

# Associated calculater functions for consistency
send2Calc() {
 echo "$*" >&${calcIn}
}

Calc() {
 echo "$*" >&${calcIn}
 read junk <&${calcOut}
 echo ${junk}
}

# Setup calculator environment with intenal variables and functions
send2Calc "
  scale = 20
  pir = a(1)*4/180
  define int(x) { auto os;os=scale;scale=0;x/=1;scale=os;return(x) }
"

# Move cursor to top left
tputHome=$(tput home)
clear

# Setup the environment
declare -i h=0 w=0 
declare -i xPos=0
declare -i x=0 y=0
declare -i xOff=2 yOff=40

declare -i xSteps=1 ySteps=1
declare -i xSpace=2 ySpace=2
declare -i r=255 g=0 b=0 rD=-1 gD=1 bD=1
declare -i oR=r oG=g oB=b oRD=rD oGD=gD oBD=bD
declare -i rS=-4 gS=2 bS=3
declare -A xPos yPos

# Produce checker board pattern 
declare -i checkerBoard=1		# Set to 1 if you want the checker board
declare -i checkerBoardGridSize=20	# Size of the checker board
declare -i checkerBoardOffset=0		# Checker board start position
declare -i checkerBoardOffsetInc=2	# Checker board increment, moves it.

#echo "
#> Waiting for file /tmp/go to exist before I'll start..."
#until [ -f /tmp/go ] ; do sleep 0.1 ; : ; done

# If not set or null then 
PlotOnOff=""


# Main Loop
  while SECONDS=0
  do

# Colour code
    r=$oR g=$oG b=$oB
    rD=$oRD gD=$oGD bD=$oBD
      [ $((r+(rD*rS))) -lt 0 -o $((r+(rD*rS))) -gt 255 ] && rD=-rD
      [ $((g+(gD*gS))) -lt 0 -o $((g+(gD*gS))) -gt 255 ] && gD=-gD
      [ $((b+(bD*bS))) -lt 0 -o $((b+(bD*bS))) -gt 255 ] && bD=-bD
    r+=$((rD*rS)) g+=$((gD*gS)) b+=$((bD*bS))
    oR=$r oB=$b oG=$g oRD=$rD oGB=$gD oBD=$bD

      for ((y=1; y<180; y+=ySteps))
      do

# Colour code
          [ $((r+(rD*rS))) -lt 0 -o $((r+(rD*rS))) -gt 255 ] && rD=-rD
          [ $((g+(gD*gS))) -lt 0 -o $((g+(gD*gS))) -gt 255 ] && gD=-gD
          [ $((b+(bD*bS))) -lt 0 -o $((b+(bD*bS))) -gt 255 ] && bD=-bD
        r+=$((rD*rS)) g+=$((gD*gS)) b+=$((bD*bS))


          for ((x=0; x<180; x+=xSteps))
          do

# Turn the calculated pixel OFF if it's in a checker board square hole
		  if ((checkerBoard))
		  then
		  	if (( ( (checkerBoardOffset+x+y+(y%checkerBoardGridSize)+(x%checkerBoardGridSize) )/checkerBoardGridSize) % 2 ))
			  then
				  PlotOnOff=off
			  else
				  PlotOnOff=""
			  fi
		  fi

# Calculate x & y plot point.
# Optimisation: Cache the result for future use otherwise return what's cached
            xPos[$x,$y]=${xPos[$x,$y]:=$(Calc "int(${xOff}+${x}+${y}/1.5)")}
            yPos[$x,$y]=${yPos[$x,$y]:=$(Calc "int($y/10+(s((($x+$y)*3+$x)*pir)*((90-$y)/3))+$yOff+((($y/5)+($x/10))*$ySpace))")}   

# Set the forground colour
            echo -ne "\033[38;2;$r;$g;${b}m"

# Call the plot routine
            nbp_f_Plot ${xPos[$x,$y]} ${yPos[$x,$y]} ${PlotOnOff}

# Next x value
          done
# Next x value
      done
# Show how long ti 
    tput home ; echo "Render Time: ${SECONDS}s   "

# Increment the checker board offset
    checkerBoardOffset+=${checkerBoardOffsetInc}

# Next frame
  done
