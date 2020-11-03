#!/bin/bash

### make sure it's not the root account
sudo apt update
sudo apt install -y conky-all net-tools jq curl transmission-cli fonts-symbola fonts-noto-mono fonts-font-awesome

remote_folder="https://raw.githubusercontent.com/scoony/conky-nas/main"
local_folder="$HOME"


mkdir "$local_folder/.conky"
wget --q "$remote_folder/.conkyrc" -O "$local_folder"
chmod + x "$HOME/.conkyrc"
wget --q "$remote_folder/.conky/conky-update.sh" -O "$local_folder/.conky"
chmod +x "$local_folder/.conky/conky-update.sh"
wget --q "$remote_folder/.conky/conky-nas.conf" -O "$local_folder/.conky"
bash "$local_folder/.conky/conky-update.sh"

### add to boot
### start conky
