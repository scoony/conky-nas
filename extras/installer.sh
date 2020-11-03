#!/bin/bash

### make sure it's not the root account
sudo apt update
sudo apt install -y conky-all net-tools jq curl transmission-cli fonts-symbola fonts-noto-mono fonts-font-awesome libxml2-utils

remote_folder="https://raw.githubusercontent.com/scoony/conky-nas/main"
local_folder="$HOME"


if [[ ! -d "$local_folder/.conky" ]]; then mkdir "$local_folder/.conky"; fi
wget -q "$remote_folder/.conkyrc" -O "$local_folder/.conkyrc"
chmod +x "$HOME/.conkyrc"
wget -q "$remote_folder/.conky/conky-update" -O "$local_folder/.conky/conky-update"
chmod +x "$local_folder/.conky/conky-update"
wget -q "$remote_folder/.conky/conky-nas.sh" -O "$local_folder/.conky/conky-nas.sh"
chmod +x "$local_folder/.conky/conky-nas.sh"
wget -q "$remote_folder/.conky/conky-nas.conf" -O "$local_folder/.conky/conky-nas.conf"
#bash $local_folder/.conky/conky-update"

### add to boot
### start conky
conky &
