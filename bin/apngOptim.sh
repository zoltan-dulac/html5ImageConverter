#!/bin/bash

ARGS="$*"
FILEARGS=`echo "$ARGS" | grep -v '\--'`



#################################################
# FUNCTIONS 
#################################################
# getArg(): get double dashed argument value
getArg() {
	local NAME="$1"
	local VALIFBLANK="$2"
	
	local VAL=`echo "$ARGS" | grep "\--$1"`
	
	if [ "$VAL" = "" ]
	then
		VAL="$VALIFBLANK"
	else 
		VAL=`echo $VAL | awk -F'=' '{print $2}'`
		if [ "$VAL" = "" ]
		then
			VAL="true"
		fi
	fi
	
	echo $VAL
}

#.. ifErrorPrintAndExit(ERROR, CODE): called whenever an error occurs and we want the
#   program to halt.  ERROR is message that appears in the terminal and CODE is the
#   error code that the program will return.
ifErrorPrintAndExit () {
	local PREV_RETURN="$?"
	local ERROR="$1"
	local CODE="$2"
	
	if [ "$PREV_RETURN" != "0" ]
	then
		echo "$1" 1>&2
		exit $CODE
	fi
}

#.. check to make sure there is a file to compress.
if [ `echo $FILEARGS | wc -l` != "1" ]
then
	echo "Usage: $0 <file-to-compress>"
	exit 1
fi

STUB=${1%.png}

DIMS=`identify $1 | awk '{print $3}'`
WIDTH=`echo $DIMS | awk -F"x" '{print $1}'`
HEIGHT=`echo $DIMS | awk -F"x" '{print $2}'`

rm *frame* 2> /dev/null

apngdis $1
ifErrorPrintAndExit "Cannot disassemble APNG file  $1.  Bailing." 1

FRAMES="apngframe*.png"

echo "Stiching image"
convert $FRAMES +append $STUB-appended.png

echo "Quantizing..."
pngquant --speed 1 --ext .png  --force $STUB-appended.png

#.. for now, we assume the frame delay is constant
DELAY_FILE=`ls apngframe*0.txt | head -1`
DELAY=`cat $DELAY_FILE | tr '/' ' ' | sed "s/^delay=//"`

I=0
for frame in $FRAMES 
do
	echo -n "."
	OFFSET=`expr $WIDTH \* $I`
	convert $STUB-appended.png -crop $WIDTH"x"$HEIGHT"+"$OFFSET"+"0 $frame
    ifErrorPrintAndExit "Cannot clip $frame.  Bailing" 2
	
	#.. add to frame file
	DELAYFILE=${file%.png}.txt
	DELAY=`cat $DELAY_FILE | tr '/' ' ' | sed "s/^delay=//"`
	NUM=`echo $DELAY | awk '{print $1}'`
	DEN=`echo $DELAY | awk '{print $2}'`
	DELAY=`expr $NUM \* 1000 / $DEN`
	
	if [ "$I" != "0" ]
	then
		echo "$frame; $DELAY; none; over" >> framelist.txt
	else 
		echo "$frame; $DELAY; none; source" >> framelist.txt
	fi
	I=`expr $I + 1`
done 

#using japng instead of apngasm because it doesn't like the quantized images.
java -jar ~/bin/japng.jar -out $STUB-quant.png -frames framelist.txt
#apngasm  cube-quant.png apngframe.png $DELAY -z2
ifErrorPrintAndExit "Cannot assemble cube-quant.png.  Bailing." 3

#.. Now, let's optimize the apng
echo "Optimizing..."
apngopt $STUB-quant.png
#mv $STUB-quant.opt.png $STUB-quant.png


echo "Cleaning up ..."
rm apngframe*	


exit

