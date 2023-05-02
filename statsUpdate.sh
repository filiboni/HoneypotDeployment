#!/bin/bash

current_date=$(date +"%Y-%m-%d")
new_file="/opt/dionaea/var/log/dionaea/json/dionaea.json.$current_date"
old_file="/sf_ctrl1/old.log"
result_file="/sf_ctrl1/dionaea.json"

if [ ! -f "$new_file" ]; then
    echo "New file does not exist."
    exit 1
fi

new_lines=$(grep -Fxvf "$old_file" "$new_file")
echo "$new_lines" > "$result_file"

renamed_file="/sf_ctrl1/old.log"
cp "$new_file" "$renamed_file"

echo "Operation completed Done."