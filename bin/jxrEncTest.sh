#!/bin/sh

if [ "$#" != "1" ]
then
	echo "Usage: $0 <file-to-encode>"
	exit
fi

VALID_ENCODINGS=""

COLORSPACE=`identify -format '%[channels]' *1`
if [ "$COLORSPACE" = 'rgba' -o  "$COLORSPACE" = 'rgba' ]
then
	IS_ALPHA=true
else
	IS_ALPHA=false
fi

FILESTUB=`echo $1 | awk -F'.' '{print $1}'`
TYPE="0"

convert  $1 -compress None $FILESTUB.tif

while [ "$TYPE" -le "34" ]
do
	for i in 2 3
	do
		JXR_FILE="$FILESTUB-$TYPE-$i.jxr"
		JxrEncApp -i $FILESTUB.tif -o $JXR_FILE -c $TYPE -q 0.7 -a $i -Q 60   > /dev/null 2> /dev/null
	
		if [ "$?" != "0" ]
		then
			# echo "Error: couldn't not encode for type $TYPE" 1>&2 
			rm $JXR_FILE 2> /dev/null
		else 
		
			SIZE=`ls -s $JXR_FILE  2> /dev/null | awk '{print $1}'`
			if [ "$?" != "0" ]
			then
				echo "Error: $TYPE doesn't seem like a valid image type" 1>&2
				
			elif [ "$SIZE" = "0" ]
			then
				rm $JXR_FILE 2> /dev/null
			else 
				VALID_ENCODINGS="$VALID_ENCODINGS $TYPE-$i	"
				echo "Valid: JxrEncApp -i $FILESTUB.tif -o $JXR_FILE -c $TYPE -q 0.7 -a $i -Q 60"
			fi
			
		fi
	done
	
	TYPE=`expr $TYPE + 1`
done 

echo "Valid encoding types are $VALID_ENCODINGS"