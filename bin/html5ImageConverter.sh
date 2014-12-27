#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

getFileSize () {
	TYPE="$1"
	SIZE="$2"
	echo "$LIST" | grep -- "-$SIZE.$TYPE" | awk '{printf "%.1fK", $5/1024}' 
}


getDefaultQuals () {
	INDEX=1
	while [ "$INDEX" -lt "$SIZES" ]
	do
		echo "$1/"
	done
	echo "$1"
}

BACKGROUND=`getArg background 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMgAAACWBAMAAABp8toqAAAALVBMVEUJCQkAAMAyAGoTExMWFhYdHR0AIUw9GmXAAADAAMAAwAAAwMDAwADAwMD////k4POZAAAAn0lEQVRo3u3OsRFBQRSG0W3B6IAGzGwk0AUt6EOmBK8FqVAJlEAsU4M3ov3XKIA5X7Q7d+aeW+7R7dp2OUfHaIgO+7bdJCoQCAQCgUAgEAgEAoFAIBAIBAKBQCAQCAQCgUAgEAgEAoH8AZLfaW1b5qKY1TzgFLNVng6BQCA/iWw/evY9Zn3z2rcoY+/XZmydQwgEAoFAIBAIBAKBQL4hL8jp+jVpb0RHAAAAAElFTkSuQmCC'`

CSS_CLASS="test"
OUTPUT="index"
NO_PNG=`getArg no-png`
HAS_ALPHA=`getArg has-alpha false`
MODERNIZR_SRC=`getArg 'modernizr-src' '../../js/modernizr.custom.29822.js'`

SIZES=`getArg renditions "320/600/1024"| tr '/' ' ')`
NUM_SIZES=${JP2_RATES[@]}

DEF_JP2_RATES=`getDefaultQuals 1.0`
DEF_JXR_QUALS=`getDefaultQuals 85`
DEF_JPG_QUALS=`getDefaultQuals 85`
DEF_WEBP_QUALS=`getDefaultQuals 80`

JP2_RATES=(`getArg jp2-rates $DEF_JP2_RATES| tr '/' ' ')` 
JPG_QUALS=(`getArg jpg-quals $DEF_JPG_QUALS | tr '/' ' ')`
JXR_QUALS=(`getArg jxr-quals $DEF_JXR_QUALS | tr '/' ' ')`
WEBP_RATES=(`getArg webp-quals $DEF_WEBP_QUALS | tr '/' ' ')`

USE_QUANT=`getArg use-quant`


if [ "$HAS_ALPHA" = "true" ]
then
	ORIG_FORMAT="png"
else
	ORIG_FORMAT="jpg"
fi


if [ "$NUM_SIZE" != ${JP2_RATES[@]} ]
then
	ifErrorPrintAndExit "There should be $NUM_SIZE JP2 renditions, but there are only "$NUM_JP2". Bailing" 100
elif [ "$NUM_SIZE" != ${JXR_RATES[@]} ]
then
	ifErrorPrintAndExit "There should be $NUM_SIZE JXR renditions, but there are only "$NUM_JXR". Bailing" 101
elif [ "$NUM_SIZE" != ${WEBP_RATES[@]} ]
then
	ifErrorPrintAndExit "There should be $NUM_SIZE WEBP renditions, but there are only "$NUM_WEBP". Bailing" 102
elif [ "$NUM_SIZE" != ${JPG_RATES[@]} ]
then
	ifErrorPrintAndExit "There should be $NUM_SIZE JPG renditions, but there are only "$NUM_JPG". Bailing" 103
fi


for file in $FILEARGS 
do
	echo "Converting $file ..." 
	$ORIG_SRCSET=""
	$JP2_SRCSET=""
	$JXR_SRCSET=""
	$WEBP_SRCSET=""
	$JPG_SRCSET=""
	$MEDIA_QUERY_CSS=""
	
	STUB=${file%.png}
	RMFILES=`ls $STUB.* $STUB_*.jxr $STUB-*-quant.png $STUB_*.jpg | grep -v $file`
	rm $RMFILES
	
	for (( i=0; i<NUM_SIZES; i++ ));
	do
		JP2_RATE=${JP2_RATES[i]}
		JXR_QUAL=${JXR_QUALS[i]}
		WEBP_QUAL=${WEBP_QUALS[i]}
		JPG_QUAL=${JPG_QUALS[i]}
		SIZE=${SIZES[i]}
		convert $STUB.png -resize $SIZE $STUB-$SIZE.png
		cutImages $STUB-$SIZE
		
		if [ "`expr $NUM_SIZES - 1`" = "$i" ]
		then 
			COMMA=""
		else
			COMMA=","
		fi
		
		#.. add to srcsets
		if [ "$USE_QUANT" ]
		then
			ORIG_SRCSET="$ORIG_SRCSET$STUB-$SIZE-quant.$ORIG_FORMAT $SIZE""w$COMMA"
		else
			ORIG_SRCSET="$ORIG_SRCSET$STUB-$SIZE.$ORIG_FORMAT $SIZE""w$COMMA"
		fi
		JP2_SRCSET="$JP2_SRCSET$STUB-$SIZE.jp2 $SIZE""w$COMMA"
		JXR_SRCSET="$JXR_SRCSET$STUB-$SIZE.jxr $SIZE""w$COMMA"
		WEBP_SRCSET="$WEBP_SRCSET$STUB-$SIZE.webp $SIZE""w$COMMA"
		JPG_SRCSET="$JPG_SRCSET$STUB-$SIZE.jxr $SIZE""w$COMMA"
		
		LIST=`ls -l $STUB-$SIZE.jpg $STUB-$SIZE.jp2 $STUB-$SIZE.jxr $STUB-$SIZE.webp  $STUB-$SIZE.png | sed 's/Domain Users/xxx/g' `
		
		MEDIA_QUERY_CSS="$MEDIA_QUERY_CSS
		@media (max-width: $SIZE""px) {
			[data-type=original]:after {
		    	content: '`getFileSize $ORIG_FORMAT $SIZE`'
		    }
		
			html.jpeg2000 .size:after {
				content: '`getFileSize jp2 $SIZE`';
			}
			
			html.jpegxr .size:after {
				content: '`getFileSize jxr $SIZE`';
			}
			
			html.webp .size:after {
				content: '`getFileSize webp $SIZE`';
			}
		}
		"
		
		
	done
	
	ORIG_FILESIZE=`ls -l $file | sed 's/Domain Users/xxx/g' | awk '{printf "%.1fK", $5/1024}'`
	

	
	HTML="<!doctype html>
	<html lang='en' class='no-js'>
	<head>
	  <meta charset='UTF-8'>
	  <meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1.0'>
	  <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,300,700' rel='stylesheet' type='text/css'>
	
	  <link rel='stylesheet' href='../../js/image-comparison-slider/css/reset.css'> <!-- CSS reset -->
	  <link rel='stylesheet' href='../../js/image-comparison-slider/css/style.css'> <!-- Resource style -->
	  <style>
	  .cd-image-container img {
	  	background-image: url($BACKGROUND);
	  	background-size: 100vw auto;
	  }
	  $MEDIA_QUERY_CSS
	  </style>
	    
	  <title>html5ImageConverter - $STUB</title>
	  
	  
	  
	  <script src='$MODERNIZR_SRC'></script>
	  <script async=true src=../../js/picturefill.js></script>
	
	</head>
	<!--[if lt IE 7 ]> <body class='ie6 ie8down ie9down custom oldIE'> <![endif]-->
	<!--[if IE 7 ]>    <body class='ie7 ie8down ie9down custom oldIE'> <![endif]-->
	<!--[if IE 8 ]>    <body class='ie8 ie8down ie9down custom oldIE'> <![endif]-->
	<!--[if IE 9 ]>    <body class='ie9 ie9down custom oldIE'> <![endif]-->
	<!--[if (gt IE 9) ]><body class='modern custom'> <![endif]-->
	<!--[!(IE)]><!--> <body class='notIE modern custom'> <!--<![endif]-->
	  <header>
	    $0 $*<br />
	
	  </header>
	  <figure class='cd-image-container'>
	  <picture title='alternative image format'>
		  <!--[if IE 9]><video style='display: none;'><![endif]-->
		  <source srcset='$ORIG_SRCSET' />
		  <!--[if IE 9]></video><![endif]-->
	      <img srcset='$ORIG_SRCSET'  />
	  </picture>
	  
	    <span class='cd-image-label' data-type='original'>$ORIG_FORMAT </span>
	
	    <div class='cd-resize-img'> <!-- the resizable image on top -->
	      <picture title='alternative image format'>
	            <!--[if IE 9]><video style='display: none;'><![endif]-->
	            <source srcset='$JXR_SRCSET' type='image/vnd.ms-photo'>
	            <source srcset='$JP2_SRCSET' type='image/jp2'>
	            <source srcset='$WEBP_SRCSET' type='image/webp'>
	            <!--[if IE 9]></video><![endif]-->
	            <img srcset='$ORIG_SRCSET'  />
	      </picture>
	      <span class='cd-image-label alt-file-type size' data-type='modified'>&nbsp;</span>
	    </div>
	
	    <span class='cd-handle'></span>
	  </figure> <!-- cd-image-container -->
	<script src='../../js/image-comparison-slider/js/jquery-2.1.1.js'></script>
	<script src='../../js/image-comparison-slider/js/jquery.mobile.custom.min.js'></script> <!-- Resource jQuery -->
	<script src='../../js/image-comparison-slider/js/main.js'></script> <!-- Resource jQuery -->
	</body>
	</html>" 
	
	echo "$HTML" > $STUB.html
done
