#!/bin/bash

remote_folder="https://raw.githubusercontent.com/scoony/conky-nas/main/.conky/"
local_folder="~/.conky/"

file=""

remote_md5=`curl -s https://raw.githubusercontent.com/scoony/conky-nas/main/.conky/conky-nas.sh | md5sum | cut -f1 -d" "`
local_md5=`md5sum ~/.conky/conky-nas.sh | cut -f1 -d" "`

if [[ $remote_md5 == $local_md5 ]]; then
  echo "No upgrade required"
else
  echo "Upgrade required"
fi
