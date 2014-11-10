#!/bin/sh

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

CSS_CLASS="test"
OUTPUT="test"

for file in $FILEARGS 
do

	STUB=${file%.png}
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
    <style>body { background: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMgAAACWBAMAAABp8toqAAAALVBMVEUJCQkAAMAyAGoTExMWFhYdHR0AIUw9GmXAAADAAMAAwAAAwMDAwADAwMD////k4POZAAAAn0lEQVRo3u3OsRFBQRSG0W3B6IAGzGwk0AUt6EOmBK8FqVAJlEAsU4M3ov3XKIA5X7Q7d+aeW+7R7dp2OUfHaIgO+7bdJCoQCAQCgUAgEAgEAoFAIBAIBAKBQCAQCAQCgUAgEAgEAoH8AZLfaW1b5qKY1TzgFLNVng6BQCA/iWw/evY9Zn3z2rcoY+/XZmydQwgEAoFAIBAIBAKBQL4hL8jp+jVpb0RHAAAAAElFTkSuQmCC') 50% 0 no-repeat; background-size: cover;}</style>
    <script async="true" src="../../js/picturefill.js"></script>
  </head>

  <body>" 
  
  for file in $FILEARGS 
  do
  	STUB=${file%.png}
  	BODY="$BODY
  	<picture>
          <!--[if IE 9]><video style='display: none;'><![endif]-->
          <source srcset='$STUB.jxr' type='image/vnd.ms-photo'>
          <source srcset='$STUB.jp2' type='image/jp2'>
          <source srcset='$STUB.webp' type='image/webp'>
          <source srcset='$STUB"-quant.png"' type='image/webp'>
          <!--[if IE 9]></video><![endif]-->
          <img srcset='$STUB"-quant.png"' alt='$STUB'>
    </picture>"
  done
  
FOOT="</body>
</html>
" 

echo "
$HEAD
$BODY
$FOOT" > $OUTPUT.html
