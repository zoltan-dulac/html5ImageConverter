#!/bin/sh

ARGS=`echo $* | tr ' ' '
'`
FILEARGS=`echo "$ARGS" | grep -v '\--'`

WEBP_QUAL=80
JP2_QUAL=80
JXR_QUAL=80

#
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

#.. cutImages(STUBS): will take a 
function cutImages() {
	local STUBS="$*"
	
	
	for stub in $STUBS
	do
		
		echo "   - jpeg " 1>&2
		convert $stub.png -define -quality=$JPEG_QUAL $stub.jpg >> log.txt
		ifErrorPrintAndExit "Creating jpg failed.  Bailing"  100
		
		echo "   - webp " 1>&2
		cwebp $stub.png -o $stub.webp -q $WEBP_QUAL >> log.txt 2> log.txt
		ifErrorPrintAndExit "Creating cwebp failed.  Bailing"  101
		
		echo "   - jp2" 1>&2
		# convert $stub.png -define jp2:quality=$JP2_QUAL $stub.jp2 >> log.txt
		convert $stub.png -compress none $stub.tif
		ifErrorPrintAndExit "Creating tif failed.  Bailing"  102
		kdu_compress -i $stub.tif -o $stub.jp2 -jp2_alpha -rate 1.0 >> log.txt 2>log.txt
		ifErrorPrintAndExit "Creating jpg2000 failed.  Bailing"  103
		
		echo "   - jxr" 1>&2
		nconvert -out jxr -q $JXR_QUAL $stub.png >> log.txt
		ifErrorPrintAndExit "Creating JPEG-XR failed.  Bailing"  104
		
		echo "   - quantized png" 1>&2
		pngquant --speed 1 --ext -quant.png -v $stub.png >> log.txt 2> log.txt
		ifErrorPrintAndExit "Creating QUANTIZED png failed.  Bailing"  104
	done
}