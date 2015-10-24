#!/bin/sh

ARGS=`echo $* | tr ' ' '
'`
FILEARGS=`echo "$ARGS" | grep -v '\--'`


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


WEBP_QUAL=`getArg webp-qual 80`
<<<<<<< HEAD

=======
>>>>>>> 8862c09ba35da30463500fe59cb130457f4a228b

if [ "$JP2_RATE" = "" ]
then
	JP2_RATE=`getArg jp2-rate 1.0`
fi

if [ "$JXR_RATE" = "" ]
then
	JXR_QUAL=`getArg jxr-qual 85`
fi

if [ "$JPEG_RATE" = "" ]
then
	JPG_QUAL=`getArg jpg-qual 70`
fi

if [ "$HAS_ALPHA" = "" ]
then
	HAS_ALPHA=`getArg has-alpha false`
fi


NO_PNG=`getArg no-png`
JXR_NCONVERT=`getArg jxr-nconvert`
IS_LOSSLESS=`getArg is-lossless`

if [ "$HAS_ALPHA" = 'true' ]
then
	JXR_FORMAT="22"
	JP2_ALPHA_PARAM="-jp2_alpha"
else 
	JXR_FORMAT="9"
	#JXR_FORMAT="22"
fi

if [ "$IS_LOSSLESS" ]
then
	echo "Performing lossless compression.  Any quality rates will be overridden."
	JP2_PARAMS="$JP2_PARAMS Creversible=yes"
	JXR_QUAL="100"
	WEBP_QUAL="100"
	JPG_QUAL="100"
fi


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

#.. cutImages(STUBS): will take the png version and convert to all the different formats. 
function cutImages() {
	local STUBS="$*"
	
	
	for stub in $STUBS
	do
		
		if [ "$HAS_ALPHA" != "true" ]
		then
			
			echo "   - jpeg (Quality: $JPG_QUAL)" 1>&2
			convert $stub.png -define quality=$JPG_QUAL $stub.jpg >> log.txt
			ifErrorPrintAndExit "Creating jpg failed.  Bailing"  100
		fi
		
		echo "   - webp (Quality: $WEBP_QUAL)" 1>&2
		cwebp $stub.png -o $stub.webp -q $WEBP_QUAL >> log.txt 2> log.txt
		ifErrorPrintAndExit "Creating cwebp failed.  Bailing"  101
		
		echo "   - jp2 (Rate: $JP2_RATE)" 1>&2
		# convert $stub.png -define jp2:quality=$JP2_QUAL $stub.jp2 >> log.txt
		convert $stub.png -compress none -define tiff:alpha=associated  $stub.tif
		ifErrorPrintAndExit "Creating tif failed.  Bailing"  102
		
		kdu_compress -i $stub.tif -o $stub.jp2  $JP2_ALPHA_PARAM $JP2_PARAMS -rate $JP2_RATE >> log.txt 2>log.txt
		
		ifErrorPrintAndExit "Creating jpg2000 failed.  Bailing"  103
		
		if [ "$JXR_NCONVERT" != "" ]
		then
			echo "   - jxr $JXR_QUAL (using nconvert, Quality: $JXR_QUAL)" 1>&2
			nconvert -out jxr -q $JXR_QUAL $stub.png >> log.txt
		else
			echo "   - jxr $JXR_QUAL (using JxrEncApp, Quality: $JXR_QUAL)" 1>&2
			rm $stub.tif
			convert $stub.png  -compress none   $stub.tif >> log.txt 2>> log.txt
			ifErrorPrintAndExit "Creating tmp TIF for JXR failed. Bailing" 104
			
			JXRENC_QUAL=`awk "BEGIN{print $JXR_QUAL/100}"`
			
			JxrEncApp -i $stub.tif -o $stub.jxr -c $JXR_FORMAT -q $JXRENC_QUAL 1>> log.txt 2>> log.txt
			
			if [ "$?" != "0" ]
			then
				echo "Cannot save JXR using format $JXR_FORMAT. Trying 22 " 1>&2
				JxrEncApp -i $stub.tif -o $stub.jxr -c 22 -q $JXRENC_QUAL 1>> log.txt 2>> log.txt
			fi
		fi
		
		#JxrEncApp -i $stub.tif -o $stub.jxr -c 22 -q 0.7 -a 3 -Q 60   
		ifErrorPrintAndExit "Creating JPEG-XR failed.  Bailing"  104
		
		if [ "$NO_PNG" != "true" ]
		then
			echo "   - quantized png" 1>&2
			pngquant --speed 1 --ext -quant.png -v $stub.png >> log.txt 2> log.txt
			ifErrorPrintAndExit "Creating QUANTIZED png failed.  Bailing"  104
		fi
		
		rm $stub.tif
		
		if [ "$IS_LOSSLESS" != "true" -a "$HAS_ALPHA" != "true" ]
		then
			rm $stub.png
		fi
	done
}

#.. 