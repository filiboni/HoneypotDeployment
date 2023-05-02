#!/bin/bash

# Crea il file JSON
output_file="/media/sf_ctrl1/loginForm.json"
echo "[" > "$output_file"

# Tail del file
tail -f "/opt/dionaea/var/log/dionaea/dionaea.log" | while IFS= read -r line
do
    if [[ $line == *"GET /?uname"* ]]; then
        # Estrapola i dati necessari dal log
        timestamp=$(echo "$line" | grep -oP '\[\K[^]]+')
        uname=$(echo "$line" | grep -oP 'uname=\K[^&]+')
        psw=$(echo "$line" | grep -oP 'psw=\K[^&]+')

        # Salva i dati nel JSON
        echo "  {" >> "$output_file"
        echo "    \"timestamp\": \"$timestamp\"," >> "$output_file"
        echo "    \"username\": \"$uname\"," >> "$output_file"
        echo "    \"password\": \"$psw\"" >> "$output_file"
        echo "  }," >> "$output_file"
    fi
done

# chiudi il file JSON
truncate -s-2 "$output_file"
echo "]" >> "$output_file"

