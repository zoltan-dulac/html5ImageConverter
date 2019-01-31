#!/bin/bash

#.. location of mozjpeg version of cjpeg, in order to prevent 
#  you from using the wrong one
MOZJPEG="/opt/local/bin/cjpeg"

ARGS=`echo $* | tr ' ' '
'`
FILEARGS=`echo "$ARGS" | grep -v '\--' | head -1`

#.. set the options up as an array
declare -a options
OPTIONS_ARGS=`echo "$ARGS" | grep "^--" | sed "s/^--//g"`

OPTIONINDEX=0
for i in $OPTIONS_ARGS
do
  OPTIONNAME=`echo $i | awk -F'=' '{print $1}'`
  OPTIONVAL=`echo $i | awk -F'=' '{print $2}'`
  if [ "$OPTIONVAL" = "" ]
  then
    OPTIONVAL="true"
  fi
  
  # options[$OPTIONNAME]="$OPTIONVAL" does not work in bash 3, so we must do
  # this workaround found at 
  # http://stackoverflow.com/questions/6047648/bash-4-associative-arrays-error-declare-a-invalid-option
  
  options[$OPTIONINDEX]=$OPTIONNAME::$OPTIONVAL
  OPTIONINDEX=`expr $OPTIONINDEX + 1`
  
done

#
# getArg(): get double dashed argument value
getArg() {

  local NAME="$1"
  local VALIFBLANK="$2"
  
  local VAL=""
  local ARRKEY
  local ARRVAL
  local ARRITEM
  
  for index in "${options[@]}"
  do
    ARRKEY="${index%%::*}"
    
    if [ "$ARRKEY" = "$NAME" ]
    then
      VAL="${index##*::}"
      break
    fi
    done
    
  if [ "$VAL" = "" ]
  then
    VAL="$VALIFBLANK"
  fi
  
  #echo checking $1 is $VAL 1>&2
  echo $VAL
}


WEBP_QUAL=`getArg webp-qual 80`

if [ "$JP2_RATE" = "" ]
then
  JP2_RATE=`getArg jp2-rate 1.0`
fi

if [ "$JXR_RATE" = "" ]
then
  JXR_QUAL=`getArg jxr-qual 85`
fi

if [ "$JPEG_QUAL" = "" ]
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
USE_MOZJPEG=`getArg use-mozjpeg`
JXR_IE9_FIX=`getArg jxr-ie9-fix`
IS_SHARP=`getArg is-sharp`
COMPRESS_SVG=`getArg compress-svg`
KEEP_TEMP_DIR=`getArg keep-temp-dir`

SCRIPT_DIR="$(dirname "$0")"

#
# This ensures the images appear consistant between all browsers.
# Safari is the one we nee to worry about.
#

IM_COLORSPACE_NORM_OPTIONS="-profile $SCRIPT_DIR/../data/sRGB_IEC61966-2-1_black_scaled.icc"

if [ "$IS_SHARP" = "true" ]
then
  WEBP_SHARP="-sharpness 0"
fi

if [ "$HAS_ALPHA" = 'true' ]
then
  JXR_FORMAT="22"
  JP2_ALPHA_PARAM="-jp2_alpha"
  WEBP_ALPHA_PARAM="-af -f 0 -alpha_q 80"
else 
  JXR_FORMAT="9"
  #JXR_FORMAT="22"
fi

if [ "$IS_LOSSLESS" = "true" ]
then
  echo "Performing lossless compression.  Any quality rates will be overridden."
  JP2_PARAMS="$JP2_PARAMS Creversible=yes"
  JXR_QUAL="100"
  WEBP_QUAL="100"
  JPG_QUAL="100"
fi

if [ "$JXR_IE9_FIX" = "true" ]
then
  JXR_OPTNS="-l 0"
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
    echo 1>&2
    echo "$ERROR" 1>&2
    echo 1>&2
    
    if [ "$TMPDIR" != "" ]
    then
      if [ "$KEEP_TEMP_DIR" = "true" ]
      then
        echo "Bailing.  You can check the working files in $TMPDIR"
      else
        echo "Removing $TMPDIR.  To keep temp dir, please use --keep-temp-dir at runtime"
        cd /
        rm -rf $TMPDIR
      fi
    fi
    
    exit $CODE
  fi
  
}

function printFinalMessages {
  if [ "$COMPRESS_SVG" = "true" ]
  then
    echo "
    
### PLEASE NOTE ###

Since you are creating SVGZ files with the --compress-svg option,
we are installing an .htaccess file for you, so your web server
will serve these files to the browser correctly.  You may want
to consider doing a global config for .svgz files if you use them
a lot.  See http://kaioa.com/node/45 for more information."

    echo "AddType image/svg+xml svg svgz
AddEncoding gzip svgz" > .htaccess
  fi
}

function toJPEG {
  local infile="$1"
  local outfile="$2"

  if [ "$USE_MOZJPEG" = "true" -a "$MOZJPEG" != "" ]
  then
    echo "   - jpeg using mozjpeg (Quality: $JPG_QUAL)"
    echo "Converting to PPM"
    convert $1 $1.ppm
    MOZ_JPEG_SUCCESS="$?"
    
    if [ "$MOZ_JPEG_SUCCESS" = "0" ]
    then
	    CMD="$MOZJPEG -quality $JPG_QUAL -outfile $2 $1.ppm"
	    echo "Command: $CMD"
	    $CMD >> log.txt
	    MOZ_JPEG_SUCCESS="$?"
	  fi
	  
	  #.. This needs to remain a separate if from the one above since the one 
	  #   above changes the value of $MOZ_JPEG_SUCCESS
    if [ "$MOZ_JPEG_SUCCESS" != "0" ]
    then
      echo "mozjpeg failed (maybe you didn't set the value of MOZ_JPEG" 
      echo "in functions.sh correctly or it's not installed)."
      echo "Falling back to ImageMagick."
    fi
  fi
  
  if [ "$USE_MOZJPEG" != "true" -o "$MOZ_JPEG_SUCCESS" != "0" ]
  then
    echo "   - jpeg using ImageMagick (Quality: $JPG_QUAL)" 1>&2
    echo "convert $1 -define quality=$JPG_QUAL $IM_COLORSPACE_NORM_OPTIONS  $2" 1>&2
    convert $1 -define quality=$JPG_QUAL $IM_COLORSPACE_NORM_OPTIONS  $2 >> log.txt
    ifErrorPrintAndExit "Creating jpg failed.  Bailing"  100
  fi
}


function createJPEGwithSVGfilter () {
      local stub=$1
      

      # First, create the mask.
      convert $stub.png -alpha extract -colorspace Gray $stub"_alpha.png"
      ifErrorPrintAndExit "Error extracting alpha channel from $stub.png.  Bailing"  200
      
      #.. Next, convert the mask to a jpg
      toJPEG $stub"_alpha.png" $stub"_alpha.jpg"
      ifErrorPrintAndExit "Could not convert $stub"_alpha.png" to JPEG format.  Bailing"  201
      
      #.. Next, convert the original image to JPEG
      toJPEG $stub".png" $stub".jpg"
      ifErrorPrintAndExit "Could not convert $stub".png" to JPEG format.  Bailing"  202

      #.. Finally, create the SVG wrapper around the image
      local DIMS=`identify $stub.png | awk '{print $3}'`
      local WIDTH=`echo $DIMS | awk -F"x" '{print $1}'`
      local HEIGHT=`echo $DIMS | awk -F"x" '{print $2}'`
      local BASE64ORIG=`cat $stub'.jpg' | base64`
      ifErrorPrintAndExit "Could not convert $stub".jpg" to base64.  Bailing"  203
      
      local BASE64ALPHA=`cat $stub'_alpha.jpg' | base64`
      ifErrorPrintAndExit "Could not convert $stub"_alpha.jpg" to base64.  Bailing"  204
      
      #.. Remove the intermediate files
      rm $stub"_alpha.png" $stub"_alpha.jpg" $stub".jpg"
      
      echo 'Creating SVG'
      echo '<svg xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 '$WIDTH' '$HEIGHT'" width="'$WIDTH'" height="'$HEIGHT'" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <mask id="a" maskUnits="userSpaceOnUse" maskContentUnits="userSpaceOnUse">
      <image width="'$WIDTH'px" height="'$HEIGHT'px" xlink:href="data:image/jpeg;base64,'$BASE64ALPHA'"></image>
    </mask>
  </defs>
  <image style="mask: url(#a);" xlink:href="data:image/jpeg;base64,'$BASE64ORIG'" height="100%" width="100%" />
</svg>' > $stub.svg

      if [ "$COMPRESS_SVG" = "true" ]
      then
        echo "Compressing SVG"
        gzip -9 $stub.svg
        ifErrorPrintAndExit "Problem gzipping $stub.svg (is gzip installed?).  Bailing"  205
        mv $stub.svg.gz $stub.svgz 
      fi
}

#.. cutImages(STUBS): will take the png version and convert to all the different formats. 
function cutImages() {
  local STUBS="$*"
  
  
  for stub in $STUBS
  do
    
    #.. If this is not an alpha image, let's create the jpeg
    if [ "$HAS_ALPHA" != "true" ]
    then
      toJPEG $stub.png $stub.jpg
    
    #.. if this is *not* an alpha image let's create a JPEG with mask that we can
    #   use in an SVG.
    else 
      createJPEGwithSVGfilter $stub
    fi
    
    echo "   - webp (Quality: $WEBP_QUAL)" 1>&2
    echo "cwebp $stub.png -o $stub.webp -q $WEBP_QUAL $WEBP_SHARP -metadata all $WEBP_ALPHA_PARAM"
    cwebp $stub.png -o $stub.webp -q $WEBP_QUAL $WEBP_SHARP -metadata all $WEBP_ALPHA_PARAM >> log.txt 2>> log.txt
    ifErrorPrintAndExit "Creating cwebp failed.  Bailing"  101
    
    echo "   - jp2 (Rate: $JP2_RATE)" 1>&2
    # convert $stub.png -define jp2:quality=$JP2_QUAL $stub.jp2 >> log.txt
    convert $stub.png -compress none -define tiff:alpha=associated  $stub.tif
    ifErrorPrintAndExit "Creating tif failed.  Bailing"  102
    
    kdu_compress -i $stub.tif -o $stub.jp2  $JP2_ALPHA_PARAM $JP2_PARAMS -rate $JP2_RATE >> log.txt 2>>log.txt
    
    ifErrorPrintAndExit "Creating jpg2000 failed.  Bailing"  103
    
    if [ "$JXR_NCONVERT" != "" ]
    then
      echo "   - jxr $JXR_QUAL (using nconvert, Quality: $JXR_QUAL)" 1>&2
      nconvert -out jxr -q $JXR_QUAL $stub.png >> log.txt
    else
      echo "   - jxr $JXR_QUAL (using JxrEncApp, Quality: $JXR_QUAL)" 1>&2
      rm $stub.tif
      convert $stub.png  -compress none  $stub.tif >> log.txt 2>> log.txt
      ifErrorPrintAndExit "Creating tmp TIF for JXR failed. Bailing" 104
      
      JXRENC_QUAL=`awk "BEGIN{print $JXR_QUAL/100}"`
      
      JxrEncApp -i $stub.tif -o $stub.jxr -c $JXR_FORMAT -q $JXRENC_QUAL $JXR_OPTNS 1>> log.txt 2>> log.txt
      
      if [ "$?" != "0" ]
      then
        echo "Cannot save JXR using format $JXR_FORMAT. Trying 22 " 1>&2
        JxrEncApp -i $stub.tif -o $stub.jxr -c 22 -q $JXRENC_QUAL  1>> log.txt 2>> log.txt
      fi
    fi
    
    #JxrEncApp -i $stub.tif -o $stub.jxr -c 22 -q 0.7 -a 3 -Q 60   
    ifErrorPrintAndExit "Creating JPEG-XR failed.  Bailing"  104
    
    if [ "$NO_PNG" != "true" ]
    then
      echo "   - quantized png" 1>&2
      pngquant --speed 1 --ext -quant.png -v $stub.png >> log.txt 2>> log.txt
      ifErrorPrintAndExit "Creating QUANTIZED png failed.  If it is not installed, 
you can get the latest at https://pngquant.org/.  Bailing" 104
    fi
    
    rm $stub.tif
    
    if [ "$IS_LOSSLESS" != "true" -a "$HAS_ALPHA" != "true" ]
    then
      rm $stub.png
    fi
  done
}

#.. 