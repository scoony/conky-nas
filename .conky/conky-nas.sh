 #!/bin/bash
 
 ## CONFIG
 #########
 font_title="\${font Ubuntu:bold:size=10}"
 font_standard="\${font Noto Mono:normal:size=8}"
 font_extra="\${font sans-serif:normal:size=8}"
 txt_align_right="\${alignr}"
 txt_align_center="\${alignc}"
 user_avatar="~/.conky/avatar.png"
 transmission_login=""
 transmission_password=""
 transmission_ip=""
 transmission_port=""
 plex_ip=""
 plex_port=""
 plex_token=""
 
 ## DONT EDIT AFTER THIS
 #######################
 
## Load config (if exist)
if [ -f ~/.conky/conky-nas.conf ]; then
  echo "ok"
## source ~/.conky/conky-nas.conf
fi

## Check local language and apply MUI
os_language=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
if [ -f "~/.conky/MUI/"$os_language".lang" ]; then
  script_language=`echo "~/.conky/MUI/"$os_language".lang"`
else
  script_language=`echo "~/.conky/MUI/default.lang"`
fi
##source $script_language

#### Let's start
if [ -f ~/.conky/avatar.png ]; then
  echo "\${image $user_avatar -p 238,3 -s 60x60 -f 86400}"
fi
echo "\${voffset -10}\${font sans-serif:bold:size=18}\${alignc}\${time %H:%M}\${font}"
echo "${txt_align_center}\${time %A %d %B}"
echo "\${font}\${voffset -4}"
echo "${font_title}SYSTEM \${hr 2}"

