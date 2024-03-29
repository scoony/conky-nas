#!/bin/bash

remote_folder="https://raw.githubusercontent.com/scoony/conky-nas/main"
user_path="$HOME"
log_install="$user_path/install-conky-nas.log"
log_install_echo="| tee -a $log_install"
my_printf="\r                                                                             "


## Check local language and apply MUI
os_language=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
check_language=`curl -s "https://raw.githubusercontent.com/scoony/conky-nas/main/.conky/MUI/$os_language.lang"`
if [[ "$check_language" == "404: Not Found" ]]; then
  os_language="en"
fi
source <(curl -s https://raw.githubusercontent.com/scoony/conky-nas/main/.conky/MUI/$os_language.lang)


### make sure it's not the root account
eval 'echo -e "\e[43m-------------------- $mui_installer_title --------------------\e[0m"' $log_install_echo
if [ "$(whoami)" == "root" ]; then
  eval 'echo -e "$mui_installer_fail"' $log_install_echo
  exit 1
fi


## apt update
sudo apt update 2>/dev/null >> $log_install &
pid=`ps aux | grep "apt update" | sed '/grep/d'`
spin='-\|/'
i=0
while [ "$pid" != "" ]; do
  i=$(( (i+1) %4 ))
  printf "\r[  ] $mui_installer_apt_update ${spin:$i:1}"
  sleep .1
  pid=`ps aux | grep "apt update" | sed '/grep/d'`
done
printf "$my_printf" && printf "\r"
eval 'echo -e "[\e[42m\u2713 \e[0m] $mui_installer_apt_update_done"' $log_install_echo


## install applications
sudo apt install -y conky-all acpi net-tools jq curl mlocate transmission-cli fonts-symbola fonts-noto-mono fonts-font-awesome libxml2-utils smartmontools nvme-cli 2>/dev/null >> $log_install &
pid=`ps aux | grep "apt install" | sed '/grep/d'`
spin='-\|/'
i=0
while [ "$pid" != "" ]; do
  i=$(( (i+1) %4 ))
  printf "\r[  ] $mui_installer_apt_install ${spin:$i:1}"
  sleep .1
  pid=`ps aux | grep "apt install" | sed '/grep/d'`
done
sudo apt install -f -y 2>/dev/null >> $log_install &
pid=`ps aux | grep "apt install" | sed '/grep/d'`
spin='-\|/'
i=0
while [ "$pid" != "" ]; do
  i=$(( (i+1) %4 ))
  printf "\r[  ] $mui_installer_apt_install ${spin:$i:1}"
  sleep .1
  pid=`ps aux | grep "apt install" | sed '/grep/d'`
done
printf "$my_printf" && printf "\r"
eval 'echo -e "[\e[42m\u2713 \e[0m] $mui_installer_apt_install_done"' $log_install_echo


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
    printf "\r[  ] $mui_installer_wget basename $(basename ${current_file}) ... ${spin:$i:1}" 
    sleep .1
  done
  chmod +x "${user_path}${current_file}"
done
printf "$my_printf" && printf "\r"
eval 'echo -e "[\e[42m\u2713 \e[0m] $mui_installer_wget_done"' $log_install_echo


## launch of conky-update
eval 'echo -e "[\e[42m\u2713 \e[0m] $mui_installer_conkyupdate"' $log_install_echo
nohup "$user_path/.conky/conky-update" > /dev/null 2>/dev/null &


### add to boot
eval 'echo -e "[\e[42m\u2713 \e[0m] $mui_installer_autostart_start"' $log_install_echo
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


## it's time to launch it
nohup conky > /dev/null 2>/dev/null &