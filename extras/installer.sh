#!/bin/bash

remote_folder="https://raw.githubusercontent.com/scoony/conky-nas/main"
user_path="$HOME"
log_install="install-conky-nas.log"
log_install_echo="| tee -a $fichier_log_perso"
my_printf="\r                                                                             "


### make sure it's not the root account
eval 'echo -e "\e[43m-------------------- CONKY NAS INSTALLATION --------------------\e[0m"' $log_install_echo
if [ "$(whoami)" == "root" ]; then
  eval 'echo -e "[ FAIL ] Do NOT run this script as root!"' $log_install_echo
  exit 1
fi

## apt update
sudo apt update 2>/dev/null >> $log_install
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
  do
  i=$(( (i+1) %4 ))
  printf "\r[  ] Update respository ... ${spin:$i:1}"
  sleep .1
done
printf "$my_printf" && printf "\r"
eval 'echo -e "[\e[42m\u2713 \e[0m] Update done"' $log_install_echo

## install applications
sudo apt install -y conky-all net-tools jq curl transmission-cli fonts-symbola fonts-noto-mono fonts-font-awesome libxml2-utils 2>/dev/null >> $log_install &
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
  do
  i=$(( (i+1) %4 ))
  printf "\r[  ] Installing packages in progress ... ${spin:$i:1}"
  sleep .1
done
printf "$my_printf" && printf "\r"
eval 'echo -e "[\e[42m\u2713 \e[0m] Install packages done"' $log_install_echo


## download files
file001="/.conky/conky-nas.conf"
file002="/.conky/conky-update"
file003="/.conkyrc"

if [[ ! -d "$user_path/.conky" ]]; then mkdir "$user_path/.conky"; fi
for current_file in $file{001..999}; do
  wget --quiet "${remote_folder}${current_file}" -O "${user_path}${current_file}" >> $log_install &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
    do
    i=$(( (i+1) %4 ))
    printf "\r[  ] Downloading basename $(basename ${current_file}) ... ${spin:$i:1}" 
    sleep .1
  done
  if [[ "$current_file" =~ ".sh" ]]; then
    chmod +x "${user_path}${current_file}"
  fi
done
printf "$my_printf" && printf "\r"
eval 'echo -e "[\e[42m\u2713 \e[0m] conky updater launched"' $log_install_echo
nohup "$user_path/.conky/conky-update" > /dev/null 2>/dev/null &

### add to boot
eval 'echo -e "[\e[42m\u2713 \e[0m] Adding autostart and launching conky"' $log_install_echo
if [[ ! -d "$HOME/.config/autostart" ]]; then mkdir "$HOME/.config/autostart"; fi 
touch "$HOME/.config/autostart/Conky.desktop"
cat <<EOT >> "$HOME/.config/autostart/Conky.desktop"
#!/usr/bin/env xdg-open
[Desktop Entry]
Type=Application
Name=Conky
Exec="/usr/bin/conky"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOT

### start conky
nohup conky &
