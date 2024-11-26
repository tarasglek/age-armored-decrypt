#!/bin/sh
# Check required dependencies
for cmd in age jq; do
    if ! which $cmd >/dev/null 2>&1; then
        echo "Error: $cmd is required but not installed" >&2
        exit 1
    fi
done
# If SOPS_AGE_KEY is not set, try to load from default location
if [ -z "$SOPS_AGE_KEY" ]; then
    if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
        SOPS_AGE_KEY=$(cat "$HOME/.config/sops/age/keys.txt")
    else
        echo "Error: SOPS_AGE_KEY not set and ~/.config/sops/age/keys.txt not found" >&2
        exit 1
    fi
fi

# Create a temporary file
TEMP_FILE=$(mktemp)

# Set a trap to delete the temporary file when the script exits
trap "rm -f $TEMP_FILE" EXIT

echo $SOPS_AGE_KEY > $TEMP_FILE
jq -r . | age --decrypt -i $TEMP_FILE -
