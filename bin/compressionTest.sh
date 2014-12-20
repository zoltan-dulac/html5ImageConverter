#!/bin/bash

#.. include global functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

#################################################
# This is the only thing you need to edit 
#################################################
JS_URI="../../js/"
#################################################
# end
#################################################


ARGS=`echo $*| tr ' ' '
'`

FORMAT=`getArg file-type jpg`
FILEARGS=`echo "$ARGS" | grep -v '\--'`
MODERNIZR_SRC="$JS_URI/modernizr.custom.91878.js"
MAX_RATE=`getArg jp2-max-rate 1.0`
HAS_ALPHA=`getArg has-alpha`
RATE_INC=`awk "BEGIN{print $MAX_RATE/10}"`
BEGIN_RATE=`awk "BEGIN{print $MAX_RATE/100}"`


if [ `echo $FILEARGS | wc -w` != "1" ]
then
	echo "Usage: $0 <file-to-compress>"
	exit 1
fi


FILESTUB=`echo $FILEARGS | awk -F'.' '{print $1}'`

rm $FILESTUB-* index.html


QUAL="1"
JP2_RATE=$BEGIN_RATE
while [ "$QUAL" -le "100" ]
do
	if [ "$FORMAT" = 'jpg' ]
	then
		HAS_ALPHA=""
		convert $FILEARGS  -quality 9  $FILESTUB-$QUAL.png
	else
		cp $FILEARGS $FILESTUB-$QUAL.png
	fi
	
	JXR_QUAL="$QUAL"
	JP2_QUAL="$QUAL"
	WEBP_QUAL="$QUAL"
	JPEG_QUAL="$QUAL"
	
	cutImages $FILESTUB-$QUAL
	
	if [ "$QUAL" = "1" ]
	then
		QUAL="10"
		JP2_RATE=$RATE_INC
	else
		QUAL=`expr $QUAL + 10`
		JP2_RATE=`awk "BEGIN{print $JP2_RATE+$RATE_INC}"`
	fi
	
done

HEAD="<!DOCTYPE html>
<html lang='en'>
  <head>
    
    <title>JPEG vs WEBP Compression Test - $FILESTUB</title>
    <meta http-equiv='X-UA-Compatible' content='IE=Edge' />
    
    <style>
    table {
    	border-collapse: collapse;
    }
    
    table td {
    	vertical-align: top;
    }
    
    </style>
    <script async=true src=../../js/picturefill.js></script>
    </head>

  <body>
    <table>
    <thead>
    <tr>
	    <th>Quality</th>
	    <th>JPEG</th>
	    <th>WEBP/JPEG-2000/JPEG-XR</th>
    </tr>"
    
QUAL="1"
BODY=""
JP2_RATE="$BEGIN_RATE"

while [ "$QUAL" -le "100" ]
do

	JPEGSIZE=`ls -l $FILESTUB-$QUAL.$FORMAT | cut -c32- | awk '{print $1}'`
	WEBPSIZE=`ls -l $FILESTUB-$QUAL.webp | cut -c32- | awk '{print $1}'`
	JPTWOSIZE=`ls -l $FILESTUB-$QUAL.jp2 | cut -c32- | awk '{print $1}'`
	JXRSIZE=`ls -l $FILESTUB-$QUAL.jxr | cut -c32- | awk '{print $1}'`
	BODY="$BODY
	<tr>
		<td>$QUAL (JPEG2 RATE: $JP2_RATE)</td>
		<td><img src='$FILESTUB-$QUAL.$FORMAT' /><p>$JPEGSIZE bytes</p></td>
		<td>
			<picture>
		          <!--[if IE 9]><video style='display: none;'><![endif]-->
		          <source srcset='$FILESTUB-$QUAL.jxr' type='image/vnd.ms-photo'>
		          <source srcset='$FILESTUB-$QUAL.jp2' type='image/jp2'>
		          <source srcset='$FILESTUB-$QUAL.webp' type='image/webp'>
		          <!--[if IE 9]></video><![endif]-->
		          <img srcset='$FILESTUB-$QUAL.$FORMAT' title='no alternative image support' />
		    </picture>
			
			<p>
			WEBP: $WEBPSIZE bytes<br />
			JP2: $JPTWOSIZE bytes<br />
			JXR: $JXRSIZE bytes
			</p>
		</td>
		
	</tr>"
	if [ "$QUAL" = "1" ]
	then
		QUAL="10"
		JP2_RATE="$RATE_INC"
	else
		QUAL=`expr $QUAL + 10`
		
		JP2_RATE=`awk "BEGIN{print $JP2_RATE+$RATE_INC}"`
		
	fi
done

FOOT="</table>
</body>
</html>"

echo "$HEAD $BODY $FOOT" > index.html
	