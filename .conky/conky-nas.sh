#!/bin/bash
 
## CONFIG
#########
font_title="\${font Ubuntu:bold:size=10}"
font_standard="\${font Noto Mono:normal:size=8}"
font_extra="\${font sans-serif:normal:size=8}"
txt_align_right="\${alignr}"
txt_align_center="\${alignc}"
user_pass=""
user_avatar=""
transmission_login=""
transmission_password=""
transmission_ip=""
transmission_port=""
plex_folder="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server"
plex_ip=""
plex_port=""
plex_token=""


## DONT EDIT AFTER THIS
#######################

## Load config (if exist)
if [[ -f ~/.conky/conky-nas.conf ]]; then
  source ~/.conky/conky-nas.conf
fi

## Check local language and apply MUI
os_language=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
if [[ -f ~/.conky/MUI/$os_language.lang ]]; then
  script_language="~/.conky/MUI/$os_language.lang"
  source ~/.conky/MUI/$os_language.lang
else
  script_language="~/.conky/MUI/default.lang"
  source ~/.conky/MUI/default.lang
fi


avatar_path=`echo ~`
user_avatar_path=${user_avatar//\~/$avatar_path}
if [[ -f "$user_avatar_path" ]]; then
  echo "\${image $user_avatar -p 238,3 -s 60x60 -f 86400}"
fi
echo "\${voffset -10}\${font sans-serif:bold:size=18}\${alignc}\${time %H:%M}\${font}"
echo "${txt_align_center}\${time %A %d %B}"
echo "\${font}\${voffset -4}"

echo "${font_title}$mui_system_title \${hr 2}"
echo "${font_standard}$mui_system_host$txt_align_right\$nodename"
echo "${font_standard}$mui_system_uptime$txt_align_right\$uptime"
if [ -f /var/run/reboot-required ]; then
  echo "\${execbar 14 echo "100"}"
  echo "${font_standard}\${voffset -21}${txt_align_center}\${color black}$mui_system_reboot\${color}"
fi
echo "\${font}\${voffset -4}"

echo "${font_title}$mui_cpu_title \${hr 2}"
echo "${font_standard}\${execi 1000 grep model /proc/cpuinfo | cut -d : -f2 | tail -1 | sed 's/\s//'}"
echo "\${color lightgray}${font_standard}\${cpugraph cpu}"
echo "${font_standard}$mui_cpu_cpu \${cpu cpu}% \${cpubar cpu}"
HandBrake_process=`ps aux | grep HandBrakeCLI | sed '/grep/d'`
if [[ "$HandBrake_process" != "" ]]; then
  HandBrake_line=`cat "/opt/scripts/.convert2hdlight" | sed -n '1p'`
  if [[ "$HandBrake_line" != "Encodage terminé" ]] && [[ "$HandBrake_line" != "..." ]] && [[ "$HandBrake_line" != "" ]] && [[ "$HandBrake_line" != "Encodage en cours" ]]; then
    HandBrake_progress=`cat "/opt/scripts/.convert2hdlight" | sed -n '1p' | cut -d' ' -f2 | sed "s/(//" | sed "s/\..*//"`
	HandBrake_progress_human=`printf '%d' $HandBrake_progress`
	echo "${font_standard}$mui_cpu_handbrake $(printf "%3d" $HandBrake_progress_human)% \${execbar 6 echo $HandBrake_progress_human}"
    HandBrake_categorie=`cat "/opt/scripts/.convert2hdlight" | sed -n '5p'`
	HandBrake_file=`cat "/opt/scripts/.convert2hdlight" | sed -n '6p'`
    if [[ "$HandBrake_categorie" == "Film" ]]; then
	  echo "${font_standard}$mui_cpu_handbrake_film$txt_align_right${HandBrake_file:0:49}"
	else
	  echo "${font_standard}$mui_cpu_handbrake_serie$txt_align_right${HandBrake_file:0:49}"
	fi
  fi
fi
echo "\${font}\${voffset -4}"

echo "${font_title}$mui_memory_title \${hr 2}"
echo "${font_standard}$mui_memory_ram $txt_align_center \$mem / \$memmax $txt_align_right \$memperc%"
echo "${font_standard}\$membar"
echo "${font_standard}$mui_memory_swap $txt_align_center \${swap} / \${swapmax} $txt_align_right \${swapperc}%"
echo "${font_standard}\${swapbar}"
echo "\${font}\${voffset -4}"

echo "${font_title}$mui_diskusage_title \${hr 2}"
drives=`ls /dev/sd*[1-9]`
for drive in $drives ; do
  mount_point=`grep "^$drive " /proc/mounts | cut -d ' ' -f 2`
  if [[ "$mount_point" != "" ]]; then
    disk_free=`df $mount_point | sed 1d | awk '{print $4}'`
    disk_free_human=`df -Hl $mount_point | sed 1d | awk '{print $4}'`
    disk_used=`df $drive | sed 1d | awk '{print $3}'`
    disk_used_human=`df -Hl $mount_point | sed 1d | awk '{print $3}'`
    disk_total=`df $drive | sed 1d | awk '{print $2}'`
    disk_total_human=`df -Hl $mount_point | sed 1d | awk '{print $2}'`
    disk_usage=`df $drive | sed 1d | awk '{print $5}' | sed 's/%//'`
    echo $font_standard$mount_point ${txt_align_right}"["$(printf "%04s" $disk_free_human)" / "$(printf "%02d" $disk_usage)"%] "\${execbar 6,160 echo $disk_usage}
  fi
done
echo "\${font}\${voffset -4}"

vpn_detected=`ifconfig | grep "tun[0-9]"`
if [[ "$vpn_detected" != "" ]]; then
  echo "${font_title}$mui_network_title_secured \${hr 2}"
else
  echo "${font_title}$mui_network_title \${hr 2}"
fi
net_adapter=`ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//"`
net_adapter_speed=`cat /sys/class/net/$net_adapter/speed`
echo "${font_standard}$mui_network_adapter $txt_align_right $net_adapter ($net_adapter_speed Mbps)"
if [[ "$vpn_detected" != "" ]]; then
  echo "${font_standard}$mui_network_vpn $txt_align_right\${execi 5 systemctl is-active $vpn_service}"
  echo "${font_standard}$mui_network_ip_public $txt_align_right\${execi 1000  wget -q -O- http://ipecho.net/plain; echo}"
  echo "${font_standard}$mui_network_ip_box $txt_align_right\${execi 1000  dig -b $(hostname -I | cut -d' ' -f1) +short myip.opendns.com @resolver1.opendns.com}"
else
echo "${font_standard}$mui_network_ip_public $txt_align_right\${execi 1000  wget -q -O- http://ipecho.net/plain; echo}"
fi
echo "${font_standard}$mui_network_down \${downspeed $net_adapter}  ${txt_align_right}$mui_network_up \${upspeed $net_adapter}"
echo "\${color lightgray}\${downspeedgraph $net_adapter 40,130 } ${txt_align_right}\${upspeedgraph $net_adapter 40,130 }\$color"
echo "\${font}\${voffset -4}"

transmission_state=`systemctl show -p SubState --value transmission-daemon`
if [[ "$transmission_state" != "dead" ]]; then
  echo "${font_title}$mui_transmission_title \${hr 2}"
  echo "${font_standard}$mui_transmission_state ${txt_align_right}\${execi 5 systemctl is-active transmission-daemon}"
  if [[ "$transmission_ip" != "" ]] && [[ "$transmission_port" != "" ]] && [[ "$transmission_login" != "" ]] && [[ "$transmission_password" != "" ]]; then
    echo "${font_standard}$mui_transmission_queue ${txt_align_right}\${exec transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l | sed '/^ID/d' | sed '/^Sum:/d' | sed '/ Done /d' | wc -l} "
    transmission_down=`transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l | grep Sum: | awk '{ print $5 }' | sed "s/\..*//"`
    let transmission_down=$transmission_down*1000
    transmission_down_human=`numfmt --to=iec-i --suffix=B $transmission_down`
    transmission_up=`transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l | grep Sum: | awk '{ print $4 }' | sed "s/\..*//"`
    let transmission_up=$transmission_up*1000
    transmission_up_human=`numfmt --to=iec-i --suffix=B $transmission_up`
    echo "${font_standard}$mui_transmission_down $transmission_down_human ${txt_align_right}$mui_transmission_up $transmission_up_human"
  else
    if [[ -f "/etc/transmission-deamon/settings.json" ]]; then
      transmission_port=`echo $user_pass | sudo -kS cat /etc/transmission-daemon/settings.json 2>/dev/null | jq -r '."rpc-port"'`
      transmission_ip="localhost"
      transmission_login=`echo $user_pass | sudo -kS cat /etc/transmission-daemon/settings.json 2>/dev/null | jq -r '."rpc-username"'`
      transmission_password=`echo $user_pass | sudo -kS cat /etc/transmission-daemon/settings.json 2>/dev/null | jq -r '."rpc-password"'`
      echo "${font_standard}$mui_transmission_queue ${txt_align_right}\${exec transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l | sed '/^ID/d' | sed '/^Sum:/d' | sed '/ Done /d' | wc -l} "
      transmission_down=`transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l | grep Sum: | awk '{ print $5 }' | sed "s/\..*//"`
      let transmission_down=$transmission_down*1000
      transmission_down_human=`numfmt --to=iec-i --suffix=B $transmission_down`
      transmission_up=`transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l | grep Sum: | awk '{ print $4 }' | sed "s/\..*//"`
      let transmission_up=$transmission_up*1000
      transmission_up_human=`numfmt --to=iec-i --suffix=B $transmission_up`
      echo "${font_standard}$mui_transmission_down $transmission_down_human ${txt_align_right}$mui_transmission_up $transmission_up_human"
    else
      echo "\${execbar 14 echo "100"}"
      echo "${font_standard}\${voffset -17}${txt_align_center}\${color black}$mui_transmission_error\${color}"
    fi
  fi
  echo "\${font}\${voffset -4}"
fi

plex_state=`systemctl show -p SubState --value plexmediaserver`
if [[ "$plex_state" != "dead" ]] || [[( "$plex_ip" != "" ) && ( "$plex_port" != "" ) && ( "$plex_token" != "" )]]; then
  echo "${font_title}$mui_plex_title \${hr 2}"
  if [[ "$plex_state" != "dead" ]]; then
    echo "${font_standard}$mui_plex_state ${txt_align_right}\${execi 5 systemctl is-active plexmediaserver}"
  fi
  if [[ "$plex_token" == "" ]]; then
    plex_token=`cat "$plex_folder/Preferences.xml" | sed -n 's/.*PlexOnlineToken="\([[:alnum:]_-]*\).*".*/\1/p'` 
  fi
  if [[ "$plex_ip" == "" ]]; then
    plex_ip="localhost"
  fi
  if [[ "$plex_port" == "" ]]; then
    plex_port="32400"
  fi
  plex_xml=`curl --silent http://$plex_ip:$plex_port/status/sessions?X-Plex-Token=$plex_token`
  plex_users=`echo $plex_xml | xmllint --format - | awk '/<MediaContainer size/ { print }' | cut -d \" -f2`
  echo $font_standard"$mui_plex_streams"$txt_align_right$plex_users" "
  let num=1
  while [ $num -le $plex_users ]; do
    plex_stream=`echo $plex_xml | xmllint --format - | sed ':a;N;$!ba;s/\n/ /g' | sed "s/<\/Video> /|/g" | cut -d'|' -f$num`
    plex_user=`echo $plex_stream | grep -Po '(?<=<User id)[^>]*' | sed 's/ title="/|/g' | cut -d'|' -f2 | sed 's/".*//' | cut -d@ -f1`
    plex_transcode=`echo $plex_stream | sed 's/.* videoDecision="//' | sed 's/".*//'`
    let plex_inprogressms=`echo $plex_stream | sed 's/.* viewOffset="//' | sed 's/".*//'`
    plex_inprogress=`printf '%d:%02d:%02d\n' $(($plex_inprogressms/1000/3600)) $(($plex_inprogressms/1000%3600/60)) $(($plex_inprogressms/1000%60))`
    let plex_durationms=`echo $plex_stream | sed 's/.* duration="//' | sed 's/".*//'`
    plex_duration=`printf '%d:%02d:%02d\n' $(($plex_durationms/1000/3600)) $(($plex_durationms/1000%3600/60)) $(($plex_durationms/1000%60))`
    plex_checkepisode=`echo $plex_stream | grep 'grandparentTitle='`
    if [[ "$plex_checkepisode" != "" ]]; then
      plex_serie=`echo $plex_stream | sed 's/.* grandparentTitle="//' | sed 's/".*//'`
      plex_episode=`echo $plex_stream | sed 's/summary=.*//' | sed 's/.* index="//' | sed 's/".*//'`
      plex_season=`echo $plex_stream | sed 's/.* parentTitle="Season //' | sed 's/".*//'`
      if [[ "$plex_transcode" == "transcode" ]]; then
        echo -e "$font_extra\u25CF $font_standard$plex_serie ("$plex_season"x$(printf "%02d" $plex_episode)) $txt_align_right$plex_user"
      else
        echo -e "$font_extra\u25C9 $font_standard$plex_serie ("$plex_season"x$(printf "%02d" $plex_episode)) $txt_align_right$plex_user"
      fi
    else
      plex_title=`echo $plex_stream | sed 's/ title="/|/g' | cut -d'|' -f2 | sed 's/".*//'`
      if [[ "$plex_transcode" == "transcode" ]]; then
        echo -e "$font_extra\u25CF $font_standard${plex_title:0:30} $txt_align_right$plex_user"
      else
        echo -e "$font_extra\u25C9 $font_standard${plex_title:0:30} $txt_align_right$plex_user"
      fi
    fi
    plex_bar_progress=$(($plex_inprogressms*100/$plex_durationms))
    echo $plex_inprogress" / "$plex_duration  \${execbar echo $plex_bar_progress}
    let num=$num+1
  done
else
  echo "${font_title}$mui_plex_title \${hr 2}"
  echo "\${execbar 14 echo "100"}"
  echo "${font_standard}\${voffset -17}${txt_align_center}\${color black}$mui_plex_error\${color}"
fi
