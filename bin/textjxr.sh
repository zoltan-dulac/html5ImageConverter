#!/bin/sh

if [ "$#" != "1" ]
then
	echo "Usage - $0 <jpg or png>"
	exit 1
fi

stub=`echo $1 | awk -F"." '{print $1}'`

convert $stub.png  -compress none   $stub.tif
i=1
while [ "$i" -le "34" ]
do 
	JxrEncApp -i $stub.tif -o $stub-$i.jxr -c $i -q 0.8
	i=`expr $i + 1`
done
