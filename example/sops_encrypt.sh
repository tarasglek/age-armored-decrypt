#!/bin/sh
# Check required dependencies
for cmd in age yq jq; do
    if ! which $cmd >/dev/null 2>&1; then
        echo "Error: $cmd is required but not installed" >&2
        exit 1
    fi
done
# set -x

TEMP_FILE=$(mktemp)

# Set a trap to delete the temporary file when the script exits
trap "rm -f $TEMP_FILE" EXIT

# convert .sops.yaml to age invocation
echo age --armor -e $(cat .sops.yaml | yq -o=json | jq -r '.creation_rules[0].key_groups[0].age[] | "-r " + .') > $TEMP_FILE
chmod +x $TEMP_FILE

$TEMP_FILE | jq -R . -s
