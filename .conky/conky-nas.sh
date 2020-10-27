 #/bin/bash
 
 ## CONFIG
 #########
 font_title=""
 font_standard=""
 font_extra=""
 txt_align_right=""
 txt_align_center=""
 user_avatar=""
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
 if [[ -f ~/.conky/conky-nas.conf ]]; then
   source ~/.conky/conky-nas.conf
 fi

#### Check local language and apply MUI
os_language=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
if [[ -f ~/.conky/MUI/"$os_language".lang ]]; then
  script_language=`echo "~/.conky/MUI/"$os_language".lang"`
else
  script_language=`echo "~/.conky/MUI/default.lang"`
fi
