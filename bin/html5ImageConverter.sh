#!/bin/sh

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

IMAGE=`getArg background 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMgAAACWBAMAAABp8toqAAAALVBMVEUJCQkAAMAyAGoTExMWFhYdHR0AIUw9GmXAAADAAMAAwAAAwMDAwADAwMD////k4POZAAAAn0lEQVRo3u3OsRFBQRSG0W3B6IAGzGwk0AUt6EOmBK8FqVAJlEAsU4M3ov3XKIA5X7Q7d+aeW+7R7dp2OUfHaIgO+7bdJCoQCAQCgUAgEAgEAoFAIBAIBAKBQCAQCAQCgUAgEAgEAoH8AZLfaW1b5qKY1TzgFLNVng6BQCA/iWw/evY9Zn3z2rcoY+/XZmydQwgEAoFAIBAIBAKBQL4hL8jp+jVpb0RHAAAAAElFTkSuQmCC'`

CSS_CLASS="test"
OUTPUT="index"
NO_PNG=`getArg no-png`
HAS_ALPHA=`getArg has-alpha false`

if [ "$HAS_ALPHA" = "true" ]
then
	ORIG_FORMAT="png"
else
	ORIG_FORMAT="jpg"
fi

for file in $FILEARGS 
do

	STUB=${file%.png}
	RMFILES=`ls $STUB.* $STUB-quant.* | grep -v $file`
	rm $RMFILES
	
	#.. desktop image
	convert $STUB.png -resize 1024 $STUB-1024.png
	cutImages $STUB-1024
	
	#.. mobile image
	convert $STUB.png -resize 320 $STUB-320.png
	cutImages $STUB-320
	
	#.. tablet image
	convert $STUB.png -resize 600 $STUB-600.png
	cutImages $STUB-600
done

##
#.. produce sample sheet
##

HTML="<!doctype html>
<html lang='en' class='no-js'>
<head>
  <meta charset='UTF-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>

  <link href='http://fonts.googleapis.com/css?family=Open+Sans:400,300,700' rel='stylesheet' type='text/css'>

  <link rel='stylesheet' href='../../js/image-comparison-slider/css/reset.css'> <!-- CSS reset -->
  <link rel='stylesheet' href='../../js/image-comparison-slider/css/style.css'> <!-- Resource style -->
    
  <title>html5ImageConverter - $STUB</title>
  
  <script async=true src=../../js/picturefill.js></script>
    </head>
</head>
<body>
  <header>
    $0 $*<br />
    `ls -l $STUB.jpg $STUB.jp2 $STUB.jxr $STUB.webp  $STUB-quant.png | sed 's/Domain Users/xxx/g' | awk '{print $9": "$5", "}' | sed "s/$STUB.//g"`
  </header>
  <figure class='cd-image-container'>
    <img srcset='$STUB-320.$ORIG_FORMAT 320w, $STUB-600.$ORIG_FORMAT 600w, $STUB-1024.$ORIG_FORMAT 1024w' title='original image' />
    <span class='cd-image-label' data-type='original'>JPEG</span>

    <div class='cd-resize-img'> <!-- the resizable image on top -->
      <picture title='alternative image format'>
            <!--[if IE 9]><video style='display: none;'><![endif]-->
            <source srcset='$STUB-320.jxr 320w, $STUB-600.jxr 600w, $STUB-1024.jxr 1024w' type='image/vnd.ms-photo'>
            <source srcset='$STUB-320.jp2 320w, $STUB-600.jp2 600w,$STUB-1024.jp2' type='image/jp2'>
            <source srcset='$STUB-320.webp 320w, $STUB-600.webp 600w, $STUB-1024.webp 1024w' type='image/webp'>
            <!--[if IE 9]></video><![endif]-->
            <img srcset='$STUB-320.$ORIG_FORMAT 320w, $STUB-600.$ORIG_FORMAT 600w, $STUB-1024.$ORIG_FORMAT'  />
      </picture>
      <span class='cd-image-label' data-type='modified'>Alt</span>
    </div>

    <span class='cd-handle'></span>
  </figure> <!-- cd-image-container -->
<script src='../../js/image-comparison-slider/js/jquery-2.1.1.js'></script>
<script src='../../js/image-comparison-slider/js/jquery.mobile.custom.min.js'></script> <!-- Resource jQuery -->
<script src='../../js/image-comparison-slider/js/main.js'></script> <!-- Resource jQuery -->
</body>
</html>" 

echo "$HTML" > $OUTPUT.html
