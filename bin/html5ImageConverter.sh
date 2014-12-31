#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"


printAndExit () {
  local ERROR="$1"
  local CODE="$2"
  
  echo "$ERROR" 1>&2
  exit $CODE
}

getFileSize () {
  TYPE="$1"
  SIZE="$2"
  echo "$LIST" | grep -- "-$SIZE.$TYPE" | awk '{printf "%.1fK", $5/1024}' 
}


getDefaultQuals () {
  INDEX=1
  while [ "$INDEX" -lt "$NUM_SIZES" ]
  do
    echo -n "$1/"
    INDEX=`expr $INDEX + 1`
  done
  echo -n "$1"
}

createRenditionHTML () {
  if [ "$NO_PNG" != "true" ]
  then
    FALLBACK="<img srcset='$STUB-$SIZE"-quant.png"' alt='$STUB'>"
  else
    FALLBACK="<img srcset='$STUB-$SIZE".jpg"' alt='$STUB'>"
  fi
    
    
  echo "<!doctype html>
<html lang='en'>
  <head>
    
    <title>CSS3 Alpha Channel Image Converter</title>
    <meta http-equiv='X-UA-Compatible' content='IE=Edge' />
    <link href='$OUTPUT.css' type='text/css' rel='stylesheet' />
    <style>
      body { 
        background: url($BACKGROUND) 50% 0 no-repeat; 
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
    `ls -l $STUB-$SIZE.jpg $STUB-$SIZE.jp2 $STUB-$SIZE.jxr $STUB-$SIZE.webp $STUB-$SIZE.png $STUB-$SIZE-quant.png 2> /dev/null | sed 's/Domain Users/xxx/g' | awk '{print $9" "$5", "}'`
    </header>
  
    <picture>
          <!--[if IE 9]><video style='display: none;'><![endif]-->
          <source srcset='$STUB-$SIZE.jxr' type='image/vnd.ms-photo'>
          <source srcset='$STUB-$SIZE.jp2' type='image/jp2'>
          <source srcset='$STUB-$SIZE.webp' type='image/webp'>
          <!--[if IE 9]></video><![endif]-->
          $FALLBACK
    </picture>
  </body>
</html>
"  > $STUB-$SIZE.html
}

BACKGROUND=`getArg background 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAMgAAACWBAMAAABp8toqAAAALVBMVEUJCQkAAMAyAGoTExMWFhYdHR0AIUw9GmXAAADAAMAAwAAAwMDAwADAwMD////k4POZAAAAn0lEQVRo3u3OsRFBQRSG0W3B6IAGzGwk0AUt6EOmBK8FqVAJlEAsU4M3ov3XKIA5X7Q7d+aeW+7R7dp2OUfHaIgO+7bdJCoQCAQCgUAgEAgEAoFAIBAIBAKBQCAQCAQCgUAgEAgEAoH8AZLfaW1b5qKY1TzgFLNVng6BQCA/iWw/evY9Zn3z2rcoY+/XZmydQwgEAoFAIBAIBAKBQL4hL8jp+jVpb0RHAAAAAElFTkSuQmCC'`

CSS_CLASS="test"
OUTPUT="index"
NO_PNG=`getArg no-png`
HAS_ALPHA=`getArg has-alpha false`
MODERNIZR_SRC=`getArg 'modernizr-src' '../../js/modernizr.custom.29822.js'`
CREATE_RENDITION_HTML=`getArg 'create-rendition-html'`

SIZES=(`getArg sizes "320/600/1024"| tr '/' ' '`)

NUM_SIZES=${#SIZES[@]}

DEF_JP2_RATES=`getDefaultQuals 1.0`
DEF_JXR_QUALS=`getDefaultQuals 85`
DEF_JPG_QUALS=`getDefaultQuals 85`
DEF_WEBP_QUALS=`getDefaultQuals 80`


JP2_RATES=( `getArg jp2-rates $DEF_JP2_RATES | tr '/' ' '` )
JPG_QUALS=(`getArg jpg-quals $DEF_JPG_QUALS | tr '/' ' '`)
JXR_QUALS=(`getArg jxr-quals $DEF_JXR_QUALS | tr '/' ' '`)
WEBP_QUALS=(`getArg webp-quals $DEF_WEBP_QUALS | tr '/' ' '`)

USE_QUANT=`getArg use-quant`


if [ "$HAS_ALPHA" = "true" ]
then
  ORIG_FORMAT="png"
else
  ORIG_FORMAT="jpg"
fi

echo
if [ "$NUM_SIZES" != "${#JP2_RATES[@]}" ]
then
  if [ "${#JP2_RATES[@]}" = "1" ]
  then
    JP2_RATES=( `getDefaultQuals ${JP2_RATES[0]} | tr '/' ' '` )
  else 
    printAndExit "There should be $NUM_SIZES JP2 renditions, but there are only ${#JP2_RATES[@]}. Bailing" 100
  fi
fi

if [ "$NUM_SIZES" != ${#JXR_QUALS[@]} ]
then
  if [ "${#JXR_QUALS[@]}" = "1" ]
  then
    JXR_QUALS=( `getDefaultQuals ${JXR_QUALS[0]} | tr '/' ' '` )
    
  else 
    printAndExit "There should be $NUM_SIZES JXR renditions, but there are only ${#JXR_QUALS[@]}. Bailing" 101
  fi
fi

if [ "$NUM_SIZES" != ${#WEBP_QUALS[@]} ]
then
  if [ "${#WEBP_QUALS[@]}" = "1" ]
  then
    WEBP_QUALS=( `getDefaultQuals ${WEBP_QUALS[0]} | tr '/' ' '` )
  else
    printAndExit "There should be $NUM_SIZES WEBP renditions, but there are only ${#WEBP_QUALS[@]}. Bailing" 102
  fi
fi

if [ "$HAS_ALPHA" != "true" -a "$NUM_SIZES" -ne ${#JPG_QUALS[@]} ]
then
  if [ "${#JPG_QUALS[@]}" = "1" ]
  then
    JPG_QUALS=( `getDefaultQuals ${JPG_QUALS[0]} | tr '/' ' '` )
  else
    printAndExit "There should be $NUM_SIZES JPG renditions, but there are only ${#JPG_QUALS[@]}. Bailing" 103
  fi
fi


for file in $FILEARGS 
do
  echo "Converting $file ..." 
  ORIG_SRCSET=""
  JP2_SRCSET=""
  JXR_SRCSET=""
  WEBP_SRCSET=""
  JPG_SRCSET=""
  MEDIA_QUERY_CSS=""
  
  STUB=${file%.png}
  
  for (( i=0; i<NUM_SIZES; i++ ));
  do
    SIZE=${SIZES[i]}
    RMFILES="$STUB"-"$SIZE.* $STUB"-"$SIZE-quant.png"
    rm $RMFILES 2> /dev/null
  
  
    JP2_RATE=${JP2_RATES[i]}
    JXR_QUAL=${JXR_QUALS[i]}
    WEBP_QUAL=${WEBP_QUALS[i]}
    JPG_QUAL=${JPG_QUALS[i]}
    echo "WEBP_QUAL: $WEBP_QUAL"
    
    echo "Creating png ..."
    convert $STUB.png -resize $SIZE $STUB-$SIZE.png
    cutImages $STUB-$SIZE
    
    if [ "`expr $NUM_SIZES - 1`" = "$i" ]
    then 
      COMMA=""
      MEDIA_QUERY_BEGIN=""
      MEDIA_QUERY_END=""
    else
      COMMA=", "
      MEDIA_QUERY_BEGIN="@media (max-width: $SIZE""px) {"
      MEDIA_QUERY_END="}"
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
    
    LIST=`ls -l $STUB-$SIZE.jpg $STUB-$SIZE.jp2 $STUB-$SIZE.jxr $STUB-$SIZE.webp  $STUB-$SIZE.png 2> /dev/null | sed 's/Domain Users/xxx/g' `
    
    ORIG_SIZE=`getFileSize $ORIG_FORMAT $SIZE`
    JP2_SIZE=`getFileSize jp2 $SIZE`
    JXR_SIZE=`getFileSize jxr $SIZE`
    WEBP_SIZE=`getFileSize webp $SIZE`
    
    
    MEDIA_QUERY_CSS="
    $MEDIA_QUERY_BEGIN
      [data-type=original]:after {
          content: '$ORIG_SIZE'
        }
    
      html.jpeg2000 .size:after {
        content: '$JP2_SIZE';
      }
      
      html.jpegxr .size:after {
        content: '$JXR_SIZE';
      }
      
      html.webp .size:after {
        content: '$WEBP_SIZE';
      }
    $MEDIA_QUERY_END
    $MEDIA_QUERY_CSS
    "
    if [ "$CREATE_RENDITION_HTML" = "true" ]
    then
    	createRenditionHTML
    fi
  done
  
  ORIG_FILESIZE=`ls -l $file | sed 's/Domain Users/xxx/g' | awk '{printf "%.1fK", $5/1024}'`
  
  CREDIT=`cat credit.html 2> /dev/null`
  if [ "$?" = "0" ]
  then
  	CREDIT="<div class='credit'>$CREDIT</div>"
  fi
  
  echo "<!doctype html>
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
    $CREDIT
  <script src='../../js/image-comparison-slider/js/jquery-2.1.1.js'></script>
  <script src='../../js/image-comparison-slider/js/jquery.mobile.custom.min.js'></script> <!-- Resource jQuery -->
  <script src='../../js/image-comparison-slider/js/main.js'></script> <!-- Resource jQuery -->
  </body>
  </html>"  > $STUB.html
  
  
  
done