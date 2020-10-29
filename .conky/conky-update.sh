#!/bin/bash

remote_folder="https://raw.githubusercontent.com/scoony/conky-nas/main/.conky/"
local_folder="~/.conky/"

file001="conky-nas.sh"
file002="conky-update.sh"
file003="MUI/default.lang"
file004="MUI/fr.lang"


user_home=`echo ~`
user_path=${local_folder//\~/$user_home}
for current_file in $file{001..999}; do
  remote_md5=`curl -s ${remote_folder}$current_file | md5sum | cut -f1 -d" "`
  local_md5=`md5sum ${user_path}$current_file | cut -f1 -d" "`
  if [[ $remote_md5 == $local_md5 ]]; then
    echo "$current_file : No upgrade required"
  else
    echo "$current_file : Upgrade required"
    wget --quiet "${remote_folder}${current_file}" -O "${user_path}${current_file}"
    sed -i -e 's/\r//g' "${user_path}${current_file}"
    if [[ "$current_file" =~ ".sh" ]]; then
      chmod +x "${user_path}${current_file}"
    fi
    echo "Update Done"
  fi
done
