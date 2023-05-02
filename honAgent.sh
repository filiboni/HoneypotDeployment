#!/bin/bash
defense_mode="ON"
vm_status="ON"
dir="/ctrl"
honStatus="OFF"
echo "Hon is being monitored..."

function readDefenceStatus {
    TOKEN=TOKEN DA INSERIRE
    updates=$(curl -s "https://api.telegram.org/bot$TOKEN/getUpdates")
    text=$(echo "$updates" | jq -r '.result[-1].message.text')

    if [[ "$defense_mode" == "OFF" ]] && [[ "$text" == "/1on" ]]; then
       defense_mode="ON"
        sender.sh "Century Mode Abilitata su Hon1"
    fi

    if [[ "$defense_mode" == "ON" ]] && [[ "$text" == "/1off" ]]; then
        defense_mode="OFF"
        sender.sh "Century Mode Disabilitata su Hon1"
    fi

    if [[ "$text" == "/1r" ]] && [[ "$honStatus" == "OFF" ]]; then
        vboxmanage controlvm HON1 resume
        sender.sh "hon1 avviato"
        honStatus="ON"
    fi
}


while true; do
  readDefenceStatus
  if [ "$(ls -A $dir)" ]; then
    if [ "$defense_mode" = "ON" ]; then
      rm  "$dir"/*
      vboxmanage controlvm HON1 pause
      sender.sh "Intruso rilevato! HON1 in pausa."
      vm_status="OFF"
    else
      rm "$dir"/*
    fi
  fi
  sleep 3
done

