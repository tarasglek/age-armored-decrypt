#!/bin/sh
# Check required dependencies
for cmd in age yq jq; do
    if ! which $cmd >/dev/null 2>&1; then
        echo "Error: $cmd is required but not installed" >&2
        exit 1
    fi
done

# Find .sops.yaml by walking up directory tree
find_sops_yaml() {
    local current_dir="$PWD"
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/.sops.yaml" ]; then
            echo "$current_dir/.sops.yaml"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    echo "Error: Could not find .sops.yaml in current or parent directories" >&2
    exit 1
}
# set -x

TEMP_FILE=$(mktemp)

# Set a trap to delete the temporary file when the script exits
trap "rm -f $TEMP_FILE" EXIT

# convert .sops.yaml to age invocation
echo age --armor -e $(cat "$(find_sops_yaml)" | yq -o=json | jq -r '.creation_rules[0].key_groups[0].age[] | "-r " + .') > $TEMP_FILE
chmod +x $TEMP_FILE

$TEMP_FILE | jq -R . -s
