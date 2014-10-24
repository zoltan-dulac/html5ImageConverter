#!/bin/bash

if [ "$#" != "1" ]
then
	echo "Usage: $0 <file-to-compress>"
	exit 1
fi


#################################################
# This is the only thing you need to edit 
#################################################
JS_URI="../../js/"


FILESTUB=`echo $1 | awk -F'.' '{print $1}'`


QUAL="1"

while [ "$QUAL" -le "100" ]
do
	convert $1  -quality $QUAL  $FILESTUB-$QUAL.jpg
	cwebp -q $QUAL $1 -o $FILESTUB-$QUAL.webp
	if [ "$QUAL" = "1" ]
	then
		QUAL="10"
	else
		QUAL=`expr $QUAL + 10`
	fi
done

HEAD="<!DOCTYPE html>
<html lang='en'>
  <head>
    
    <title>JPEG vs WEBP Compression Test - $FILESTUB</title>
    <meta http-equiv='X-UA-Compatible' content='IE=Edge' />
    
    <style></style>
    <script>(function(){var WebP=new Image();WebP.onload=WebP.onerror=function(){
if(WebP.height!=2){var sc=document.createElement('script');sc.type='text/javascript';sc.async=true;
var s=document.getElementsByTagName('script')[0];sc.src='$JS_URI/webpjs-0.0.2.min.js';s.parentNode.insertBefore(sc,s);}};
WebP.src='data:image/webp;base64,UklGRjoAAABXRUJQVlA4IC4AAACyAgCdASoCAAIALmk0mk0iIiIiIgBoSygABc6WWgAA/veff/0PP8bA//LwYAAA';})();</script>
  </head>

  <body>
    <table>
    <thead>
    <tr>
	    <th>Quality</th>
	    <th>JPEG</th>
	    <th>WEBP</th>
    </tr>"
    
QUAL="1"
BODY=""

while [ "$QUAL" -le "100" ]
do
	JPEGSIZE=`ls -l $FILESTUB-$QUAL.jpg | awk '{print $5}'`
	WEBPSIZE=`ls -l $FILESTUB-$QUAL.webp | awk '{print $5}'`
	BODY="$BODY
	<tr>
		<td>$QUAL</td>
		<td><img src='$FILESTUB-$QUAL.jpg' /><p>$JPEGSIZE bytes</p></td>
		<td><img src='$FILESTUB-$QUAL.webp' /><p>$WEBPSIZE bytes</p></td>
	</tr>"
	if [ "$QUAL" = "1" ]
	then
		QUAL="10"
	else
		QUAL=`expr $QUAL + 10`
	fi
done

FOOT="</body>
</html>"

echo "$HEAD $BODY $FOOT" > index.html
	