#!/bin/bash


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
		cd $ORIGDIR
		rm -rf $TMPDIR
		exit $CODE
	fi
}

#.. check to make sure there is a file to compress.
if [ "$#" != "1" ]
then
	echo "Usage: $0 <file-to-compress>"
	exit 1
fi

ARGS="$*"
FILEARGS=`echo "$ARGS" | grep -v '\--'`
TMPDIR=/tmp/$$.apngoptim.tmp/
ORIGDIR=`pwd`

mkdir $TMPDIR
cp $1 $TMPDIR
cd $TMPDIR

STUB=${1%.png}

echo "Disassembling apng file ..." 
apngdis $1

ifErrorPrintAndExit "Cannot disassemble APNG file  $1.  Bailing." 1

echo "Quantizing frames ... " 
FRAMES="apngframe*.png"
pngquant --speed 1 --ext _s.png $FRAMES

for i in *_s.png; do mv $i `echo $i | sed "s/_s\./\./"`; done

#.. for now, we assume the frame delay is constant
DELAY_FILE=`ls apngframe*0.txt | head -1`
DELAY=`cat $DELAY_FILE | tr '/' ' ' | sed "s/^delay=//"`


echo "Assembling quantized apng ... " 
apngasm  $STUB-quant.png $FRAMES $DELAY -z2
ifErrorPrintAndExit "Cannot assemble quantized png.  Bailing." 3


echo "Cleaning up ..." 
cp $STUB-quant.png $ORIGDIR
cd $ORIGDIR
rm -rf $TMPDIR	



