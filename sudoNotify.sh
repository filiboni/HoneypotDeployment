#!/bin/bash
LOGFILE="/var/log/auth.log"
tail -n 0 -F $LOGFILE | grep --line-buffered 'sudo.*COMMAND=' | while read line
do
        sender.sh "Comando SUDO eseguito su Honey 1:        $line"
done


