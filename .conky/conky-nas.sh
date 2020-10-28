#!/bin/bash

## apt install libxml2-utils

 
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
plex_folder="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server"
plex_ip=""
plex_port=""
plex_token=""

## DONT EDIT AFTER THIS
#######################

## Load config (if exist)
if [[ -f ~/.conky/conky-nas.conf ]]; then
##  echo "ok"
  source ~/.conky/conky-nas.conf
fi

## Check local language and apply MUI
os_language=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
if [[ -f "~/.conky/MUI/"$os_language".lang" ]]; then
  script_language=`echo "~/.conky/MUI/"$os_language".lang"`
else
  script_language=`echo "~/.conky/MUI/default.lang"`
fi
my_language=$script_language
##source $my_language

if [ -f ~/.conky/avatar.png ]; then
  echo "\${image $user_avatar -p 238,3 -s 60x60 -f 86400}"
fi
echo "\${voffset -10}\${font sans-serif:bold:size=18}\${alignc}\${time %H:%M}\${font}"
echo "${txt_align_center}\${time %A %d %B}"
echo "\${font}\${voffset -4}"

echo "${font_title}SYSTEM \${hr 2}"
echo "${font_standard}Host:$txt_align_right\$nodename"
echo "${font_standard}Uptime:$txt_align_right\$uptime"
if [ -f /var/run/reboot-required ]; then
  echo "\${execbar 14 echo "100"}"
  echo "${font_standard}\${voffset -21}${txt_align_center}\${color black}REBOOT REQUIRED\${color}"
fi
echo "\${font}\${voffset -4}"


echo "${font_title}CPU \${hr 2}"
echo "${font_standard}\${execi 1000 grep model /proc/cpuinfo | cut -d : -f2 | tail -1 | sed 's/\s//'}"
echo "${font_standard}\${cpugraph cpu}"
echo "${font_standard}CPU: \${cpu cpu}% \${cpubar cpu}"
##echo "\${voffset -16}\${alignr -5}\$cpu%"
echo "\${font}\${voffset -4}"

echo "${font_title}MEMORY \${hr 2}"
echo "${font_standard}RAM $txt_align_center \$mem / \$memmax $txt_align_right \$memperc%"
echo "${font_standard}\$membar"
echo "${font_standard}SWAP $txt_align_center \${swap} / \${swapmax} $txt_align_right \${swapperc}%"
echo "${font_standard}\${swapbar}"
echo "\${font}\${voffset -4}"

echo "${font_title}DISK USAGE \${hr 2}"
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
    echo $font_standard$mount_point ${txt_align_right}"["$disk_free_human" / "$(printf "%02d" $disk_usage)"%] "\${execbar 6,160 echo $disk_usage}
  fi
done
echo "\${font}\${voffset -4}"

echo "${font_title}NETWORK \${hr 2}"
net_adapter=`ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//"`
net_adapter_speed=`cat /sys/class/net/$net_adapter/speed`
echo "${font_standard}Adapter: $txt_align_right $net_adapter ($net_adapter_speed Mbps)"
##echo "${font_standard}Link Speed: $txt_align_right $net_adapter_speed"
echo "${font_standard}VPN: $txt_align_right\${execi 5 systemctl is-active openvpnauto}"
echo "${font_standard}IP (public): $txt_align_right\${execi 1000  wget -q -O- http://ipecho.net/plain; echo}"
echo "${font_standard}IP (box): $txt_align_right\${execi 1000  dig -b $(hostname -I | cut -d' ' -f1) +short myip.opendns.com @resolver1.opendns.com}"
echo "${font_standard}Down: \${downspeed $net_adapter}  ${txt_align_right}Up: \${upspeed $net_adapter}"
echo "\${color lightgray}\${downspeedgraph $net_adapter 40,130 } ${txt_align_right}\${upspeedgraph $net_adapter 40,130 }\$color"
echo "\${font}\${voffset -4}"

echo "${font_title}TRANSMISSION \${hr 2}"
echo "${font_standard}State: ${txt_align_right}\${execi 5 systemctl is-active transmission-daemon}"
echo "${font_standard}Queue: ${txt_align_right}\${exec transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l | sed '/^ID/d' | sed '/^Sum:/d' | sed '/ Done /d' | wc -l} "
##echo "${font_standard}Down: \${exec transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l | grep Sum: | awk '{ print $5 }'} ${txt_align_right}Up: \${exec transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l | grep Sum: | awk '{ print $4 }'}"
echo "\${font}\${voffset -4}"

echo "${font_title}PLEX \${hr 2}"
echo "${font_standard}State: ${txt_align_right}\${execi 5 systemctl is-active plexmediaserver}"
token=`cat "$plex_folder/Preferences.xml" | sed -n 's/.*PlexOnlineToken="\([[:alnum:]_-]*\).*".*/\1/p'` 
plex_xml=`curl --silent http://localhost:32400/status/sessions?X-Plex-Token=$token`
plex_users=`echo $plex_xml | xmllint --format - | awk '/<MediaContainer size/ { print }' | cut -d \" -f2`
echo $font_standard"Stream(s):"$txt_align_right$plex_users" "
let num=1
  while [ $num -le $plex_users ]; do
    lestream=`echo $plex_xml | xmllint --format - | sed ':a;N;$!ba;s/\n/ /g' | sed "s/<\/Video> /|/g" | cut -d'|' -f$num`
    ##echo $lestream > ~/.conky/test$num.log
    title=`echo $lestream | sed 's/ title="/|/g' | cut -d'|' -f2 | sed 's/".*//'`
    user=`echo $lestream | grep -Po '(?<=<User id)[^>]*' | sed 's/ title="/|/g' | cut -d'|' -f2 | sed 's/".*//' | cut -d@ -f1`
    transcode=`echo $lestream | sed 's/.* videoDecision="//' | sed 's/".*//'`
    let inprogressms=`echo $lestream | sed 's/.* viewOffset="//' | sed 's/".*//'`
    inprogress=`printf '%d:%02d:%02d\n' $(($inprogressms/1000/3600)) $(($inprogressms/1000%3600/60)) $(($inprogressms/1000%60))`
	let durationms=`echo $lestream | sed 's/.* duration="//' | sed 's/".*//'`
    duration=`printf '%d:%02d:%02d\n' $(($durationms/1000/3600)) $(($durationms/1000%3600/60)) $(($durationms/1000%60))`
    checkepisode=`echo $lestream | grep 'grandparentTitle='`
    if [[ "$checkepisode" != "" ]]; then
      serie=`echo $lestream | sed 's/.* grandparentTitle="//' | sed 's/".*//'`
      episode=`echo $lestream | sed 's/summary=.*//' | sed 's/.* index="//' | sed 's/".*//'`
      season=`echo $lestream | sed 's/.* parentTitle="Season //' | sed 's/".*//'`
	  if [[ "$transcode" == "transcode" ]]; then
	    echo -e "$font_extra\u25CF $font_standard$serie ($season x $episode) $txt_align_right$user"
	    else
	    echo -e "$font_extra\u25C9 $font_standard$serie ($season x $episode) $txt_align_right$user"
	  fi
	else
	  if [[ "$transcode" == "transcode" ]]; then
	    echo -e "$font_extra\u25CF $font_standard$title $txt_align_right$user"
	   else
	  echo -e "$font_extra\u25C9 $font_standard$title $txt_align_right$user"
	fi
    fi
    bar_progress=$(($inprogressms*100/$durationms))
    echo $inprogress" / "$duration  \${execbar echo $bar_progress}
    let num=$num+1
  done
