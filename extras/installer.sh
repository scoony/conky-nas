#!/bin/bash

mkdir -p ~/.conky/MUI
wget --q ".conkyrc" -O "~/.conkyrc"
chmod + x ~/.conkyrc
wget --q "conky-update.sh" -O "~/.conky/conky-update.sh"
chmod +x ~/.conky/conky-update.sh
bash ~/.conky/conky-update.sh

### add to boot
### start conky
