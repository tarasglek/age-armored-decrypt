#!/bin/sh
# Create a temporary file
TEMP_FILE=$(mktemp)

# Set a trap to delete the temporary file when the script exits
trap "rm -f $TEMP_FILE" EXIT

echo $SOPS_AGE_KEY > $TEMP_FILE
jq -r . | age --decrypt -i $TEMP_FILE -