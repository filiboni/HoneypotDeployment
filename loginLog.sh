#!/bin/bash

o="/media/sf_ctrl1/loginForm.json"

tail -f "/opt/dionaea/var/log/dionaea/dionaea.log" | while IFS= read -r l
do
    if [[ $l == *"GET /?uname"* ]]; then
        t=$(echo "$l" | grep -oP '\[\K[^]]+')
        u=$(echo "$l" | grep -oP 'uname=\K[^&]+')
        p=$(echo "$l" | grep -oP 'psw=\K[^&]+')
#check if file exists
        if [[ -f "$o" ]]; then
            truncate -s-2 "$o"
            echo "," >> "$o"
        else
            echo "[" > "$o"
        fi

        echo "  {" >> "$o"
        echo "    \"timestamp\": \"$t\"," >> "$o"
        echo "    \"username\": \"$u\"," >> "$o"
        echo "    \"password\": \"$p\"" >> "$o"
        echo "  }" >> "$o"
        echo "]" >> "$o"
    fi
done


