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
    column=($line)
    echo "${column[0]}"$'\t'"${column[2]}" >> $temp_arp
  done <<< $(arp | sed '1d' | sed '/incomplete/d')

  mac_address=$(zenity --list --title="Configure a Device to Wake-On-Lan" \
    --width=800 --height=200 --print-column=2 \
    --separator='\t' --ok-label "Confirm" \
    --column="Name/IP" --column="MAC Adress"\
    $(cat "$temp_arp"))
  
  if [ "$?" = 1 ] ; then
    echo "Aborted"
    exit 1;
  fi
    if [ -z "$mac_address" ] ; then
    echo "None Selected"
    exit 1;
  fi

  echo "$mac_address" > "$config"
else
  read -r mac_address < "$config"
  zenity --password \
    --title="Sudo Password Required" \
    --ok-label "Wake Up!" | sudo -kS ether-wake "$mac_address"
fi

exit 0;