#!/bin/bash

config_dir="$(dirname "$(realpath "$0")")/config"
tmp_dir="$(dirname "$(realpath "$0")")/tmp"

#create temp folder if missing
if [ ! -d "$tmp_dir" ]; then
  echo "creating tmp dir"
  mkdir "$tmp_dir"
fi

#create config folder if missing
if [ ! -d "$config_dir" ]; then
  echo "creating config dir"
  mkdir "$config_dir"
fi

config="$config_dir/config.txt"
temp_arp="$tmp_dir/arp.txt"

true > "$temp_arp"

if [ ! -f "$config" ] || [ "$1" = "config" ]; then
  while read -r line; do
    IFS=$" ";column=($line);unset IFS
    echo "${column[0]}"$'\t'"${column[4]}" >> "$temp_arp"
  done <<< "$(ip n)"

  mac_address=$(zenity --list --title="Configure a Device to Wake-On-Lan" \
    --width=800 --height=200 --print-column=2 \
    --separator='\t' --extra-button "Manual" --ok-label "Confirm" \
    --column="Name/IP" --column="MAC Adress"\
    $(cat "$temp_arp"))
  
  if [ "$?" = 1 ] ; then
    if [ "$mac_address" = "Manual" ]; then
      mac_address=$(zenity --forms --title="Manual Config" \
        --text="Enter MAC Adress" --add-entry="MAC Address")
      if [ "$?" = 1 ] ; then
        echo "Aborted"
        exit 1;
      fi
    else
      echo "Aborted"
      exit 1;
    fi
  fi
    if [ -z "$mac_address" ] ; then
    echo "None Selected"
    exit 1;
  fi

  echo "$mac_address" > "$config"
else
  if [ ! -z "$1" ] ; then
    mac_address="$1"
  else 
    read -r mac_address < "$config"
  fi

  #This worked on my Fedora machine, always Dev on your target system!
  #zenity --password \
  #  --title="Sudo Password Required" \
  #  --ok-label "Wake Up!" | sudo -kS ether-wake "$mac_address"
  
  #Stolen from: https://stackoverflow.com/questions/31588035/bash-one-line-command-to-send-wake-on-lan-magic-packet-without-specific-tool
  echo -e $(echo $(printf 'f%.0s' {1..12}; printf "$(echo $mac_address | sed 's/://g')%.0s" {1..16}) | sed -e 's/../\\x&/g') | socat - UDP-DATAGRAM:255.255.255.255:4000,broadcast

fi

exit 0;
