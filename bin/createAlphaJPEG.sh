#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

FILEARGS=`echo "$ARGS" | grep -v '\--' | head -1`
JPG_QUAL=`getArg q 80`
COMPRESS_SVG=`getArg compress-svg`

for file in $FILEARGS
do
	STUB=${file%.png}
	createJPEGwithSVGfilter $STUB
done