#!/bin/bash
LOGFILE="/var/log/auth.log"
tail -n 0 -F $LOGFILE | grep --line-buffered 'sudo.*COMMAND=' | while read line
do
        TIME=$(date +%s)
        touch /media/sf_ctrl/$TIME
done

