#!/bin/bash
login_ip="$(echo $SSH_CONNECTION | cut -d " " -f 1)"
login_date="$(date +"%e %b %Y, %a %r")"
login_name="$(whoami)"

message="ALERT:New SSH login to HONEYPOT 1"$'\n'"$login_name"$'\n'"$login_ip"$'\n'"$login_date"

sender.sh "$message"


y