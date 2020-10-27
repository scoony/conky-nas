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
 
 if [[ -f ~/.conky/conky-nas.conf ]]; then
   source ~/.conky/conky-nas.conf
 fi
