#!/bin/bash

LOG_FILE="/var/log/auth.log"

tail -n0 -F "$LOG_FILE" | while read -r line; do
    # Connessioni accettate
    if echo "$line" | grep -q "Accepted"; then
        # Invia il messaggio Telegram
        sender.sh"$line"
    fi
done