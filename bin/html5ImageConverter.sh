#!/bin/sh

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

IMAGE=`getArg background 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMgAAACWBAMAAABp8toqAAAALVBMVEUJCQkAAMAyAGoTExMWFhYdHR0AIUw9GmXAAADAAMAAwAAAwMDAwADAwMD////k4POZAAAAn0lEQVRo3u3OsRFBQRSG0W3B6IAGzGwk0AUt6EOmBK8FqVAJlEAsU4M3ov3XKIA5X7Q7d+aeW+7R7dp2OUfHaIgO+7bdJCoQCAQCgUAgEAgEAoFAIBAIBAKBQCAQCAQCgUAgEAgEAoH8AZLfaW1b5qKY1TzgFLNVng6BQCA/iWw/evY9Zn3z2rcoY+/XZmydQwgEAoFAIBAIBAKBQL4hL8jp+jVpb0RHAAAAAElFTkSuQmCC'`

CSS_CLASS="test"
OUTPUT="test"
NO_PNG=`getArg no-png`

for file in $FILEARGS 
do

	STUB=${file%.png}
	RMFILES=`ls $STUB.* $STUB-quant.* | grep -v $file`
	rm $RMFILES
	
	cutImages $STUB
done

##
#.. produce sample sheet
##

HEAD="<!DOCTYPE html>
<html lang='en'>
  <head>
    
    <title>CSS3 Alpha Channel Image Converter</title>
    <meta http-equiv='X-UA-Compatible' content='IE=Edge' />
    <link href='$OUTPUT.css' type='text/css' rel='stylesheet' />
    <style>
    	body { 
    		background: url($IMAGE) 50% 0 no-repeat; 
    		background-size: cover;
    	}
    	header {
	    	position: absolute;
	    	top: 0;
	    	left: 0;
	    	width: 100%;
	    	padding: 10px;
	    	background: black;
	    	color: white;
	    	font: 15px "Arial", "Helvetica", sans-serif;
	    }
	    
	    picture {
	    	position: absolute;
	    	top: 80px;
	    	left: 10px;
	    
    	
    </style>
    <script async="true" src="../../js/picturefill.js"></script>
    <script src='//code.jquery.com/jquery-1.10.2.js'></script>
    <script src='//code.jquery.com/ui/1.11.2/jquery-ui.js'></script>
    <script>
      \$(function() {
        \$('picture' ).draggable();
      });
    </script>
  </head>

  <body>
  	<header>
  	$0 $*<br />
  	`ls -l $STUB.jpg $STUB.jp2 $STUB.jxr $STUB.webp $STUB.png $STUB-quant.png | sed 's/Domain Users/xxx/g' | awk '{print $9" "$5", "}'`
  	</header>" 
  
  for file in $FILEARGS 
  do
  	STUB=${file%.png}
  	if [ "$NO_PNG" != "true" ]
  	then
  		FALLBACK="<img srcset='$STUB"-quant.png"' alt='$STUB'>"
  	else
  		FALLBACK="<img srcset='$STUB".jpg"' alt='$STUB'>"
  	fi
  	
  	BODY="$BODY
  	<picture>
          <!--[if IE 9]><video style='display: none;'><![endif]-->
          <source srcset='$STUB.jxr' type='image/vnd.ms-photo'>
          <source srcset='$STUB.jp2' type='image/jp2'>
          <source srcset='$STUB.webp' type='image/webp'>
          <!--[if IE 9]></video><![endif]-->
          $FALLBACK
    </picture>"
  done
  
FOOT="</body>
</html>
" 

echo "
$HEAD
$BODY
$FOOT" > $OUTPUT.html
