#!/bin/sh
# set -x

TEMP_FILE=$(mktemp)

# Set a trap to delete the temporary file when the script exits
trap "rm -f $TEMP_FILE" EXIT

# convert .sops.yaml to age invocation
echo age --armor -e $(cat .sops.yaml | yq -o=json | jq -r '.creation_rules[0].key_groups[0].age[] | "-r " + .') > $TEMP_FILE
chmod +x $TEMP_FILE

$TEMP_FILE | jq -R . -s