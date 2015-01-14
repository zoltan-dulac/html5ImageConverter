#!/bin/bash


SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"


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
pwd
ls
echo cp $1 $TMPDIR
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
pwd
ls
DELAY_FILE=`ls apngframe[0-9]*.txt | head -1`
DELAY=`cat $DELAY_FILE | tr '/' ' ' | sed "s/^delay=//"`


echo "Assembling quantized apng ... " 
apngasm  $STUB-quant.png $FRAMES $DELAY -z2
ifErrorPrintAndExit "Cannot assemble quantized png.  Bailing." 3


echo "Cleaning up ..." 
cp $STUB-quant.png $ORIGDIR
cd $ORIGDIR
rm -rf $TMPDIR	



