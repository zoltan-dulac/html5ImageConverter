#!/bin/bash



#################################################
# This is the only thing you need to edit 
#################################################
JS_URI="../../js/"
#################################################
# end
#################################################


#################################################
# FUNCTIONS 
#################################################
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

ARGS=`echo $*| tr ' ' '
'`

FORMAT=`getArg file-type jpg`
FILEARGS=`echo "$ARGS" | grep -v '\--'`
MODERNIZR_SRC="$JS_URI/modernizr.custom.91878.js"


if [ `echo $FILEARGS | wc -l` != "1" ]
then
	echo "Usage: $0 <file-to-compress>"
	exit 1
fi


FILESTUB=`echo $FILEARGS | awk -F'.' '{print $1}'`


QUAL="1"

while [ "$QUAL" -le "100" ]
do
	if [ "$FORMAT" = 'jpg' ]
	then
		convert $FILEARGS  -quality $QUAL  $FILESTUB-$QUAL.jpg
	else
		convert $FILEARGS  -quality 9  $FILESTUB-$QUAL.png
	fi
	
	cwebp -q $QUAL $FILEARGS -o $FILESTUB-$QUAL.webp
	
	JP2_QUAL=`expr 40 \* $QUAL / 100`
	image_to_j2k -i $FILEARGS -o $FILESTUB-$QUAL.jp2  -c [128,128] -q $JP2_QUAL -n 1 -I -p RLCP -s 1,1
	#convert $FILEARGS -define jp2:quality=$JP2_QUAL -define jp2:number-resolutions=1  $FILESTUB-$QUAL.jp2
	
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
    <script src="$MODERNIZR_SRC"></script>
    </head>

  <body>
    <table>
    <thead>
    <tr>
	    <th>Quality</th>
	    <th>JPEG</th>
	    <th>WEBP</th>
	    <th>JPEG 2000</th>
    </tr>"
    
QUAL="1"
BODY=""

while [ "$QUAL" -le "100" ]
do
	JP2_QUAL=`expr 40 \* $QUAL / 100`


	JPEGSIZE=`ls -l $FILESTUB-$QUAL.$FORMAT | awk '{print $6}'`
	WEBPSIZE=`ls -l $FILESTUB-$QUAL.webp | awk '{print $6}'`
	JPTWOSIZE=`ls -l $FILESTUB-$QUAL.jp2 | awk '{print $6}'`
	BODY="$BODY
	<tr>
		<td>$QUAL</td>
		<td><img src='$FILESTUB-$QUAL.$FORMAT' /><p>$JPEGSIZE bytes</p></td>
		<td><img src='$FILESTUB-$QUAL.webp' /><p>$WEBPSIZE bytes</p></td>
		<td><img src='$FILESTUB-$QUAL.jp2' /><p>$JPTWOSIZE bytes (Qual: $JP2_QUAL)</p></td>
	</tr>"
	if [ "$QUAL" = "1" ]
	then
		QUAL="10"
	else
		QUAL=`expr $QUAL + 10`
	fi
done

FOOT="</table>
</body>
</html>"

echo "$HEAD $BODY $FOOT" > index.html
	