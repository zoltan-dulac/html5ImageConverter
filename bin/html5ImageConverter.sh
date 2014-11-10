#!/bin/sh

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/functions.sh"

echo "files: $FILEARGS"

for file in $FILEARGS 
do

	STUB=${file%.png}
	cutImages $STUB
done