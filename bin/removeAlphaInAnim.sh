#!/bin/bash


SCRIPT_DIR=`dirname $0`


source "$SCRIPT_DIR/functions.sh"

if [ "$#" -lt "3" ]
then
	echo "Usage: $0 <animated-png-input> <animted-png-output> <color-to-change>" 2>&1
	exit 100
fi

TMPDIR="/tmp/$$.aa.tmp"
ORIG_DIR="$PWD"

mkdir $TMPDIR
ifErrorPrintAndExit "Cannot make temp directory $TMPDIR. Bailing." 1

cp $1 $TMPDIR
ifErrorPrintAndExit "Cannot copy file $1 into $TMPDIR.  Bailing." 2

cd $TMPDIR
ifErrorPrintAndExit "Cannot cd into $TMPDIR. Bailing." 3

echo "Dissassembling APNG file ..."
apngdis $1
ifErrorPrintAndExit "Error disassembling $1.  Bailing" 4


for i in apngframe*.png
do
	echo "Removing $3 from $i."
	FILESTUB=`basename $i .png`
	color2alpha -ca $3 $i aa-$FILESTUB.png 2> $ORIG_DIR/log.txt
	ifErrorPrintAndExit "Could not create alpha frame for $i. Make sure color2alpha is in your PATH. Bailing."
done

echo "Assembling animation."

apngasm $2 aa-*.png 
ifErrorPrintAndExit "Assembling alpha anim $2 failed.  Bailing."

mv $2 $ORIG_DIR
ifErrorPrintAndExit "Canot move $2 to $ORIG_DIR. Bailing."

	