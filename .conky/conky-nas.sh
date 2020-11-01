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
  if [[ "$user_avatar_location" != "" ]]; then
    echo "\${image $user_avatar $user_avatar_location}"
  else
    echo "\${image $user_avatar -p 238,3 -s 60x60 -f 86400}"
  fi
fi
echo "\${voffset -10}${font_time}\${alignc}\${time %H:%M}\${font}"
echo "${font_date}${txt_align_center}\${time %A %d %B}"
if [[ "$user_town" != "" ]]; then
  echo "${txt_align_center}${font_weather}\${exec curl --silent wttr.in/$user_town?format=2}${font_standard}"
fi
echo "\${font}\${voffset -4}"

echo "${font_title}$mui_system_title \${hr 2}"
hdd_total=`df --total 2>/dev/null | sed -e '$!d' | awk '{ print $2 }' | numfmt --from-unit=1024 --to=si --suffix=B`
hdd_free_total=`df --total 2>/dev/null | sed -e '$!d' | awk '{ print $4 }' | numfmt --from-unit=1024 --to=si --suffix=B`
echo "${font_standard}$mui_system_host$txt_align_right\$nodename"
echo "${font_standard}$mui_system_uptime$txt_align_right\$uptime"
echo "${font_standard}$mui_system_hdd_total$txt_align_right$hdd_total"
echo "${font_standard}$mui_system_hdd_free_total$txt_align_right$hdd_free_total"
if [ -f /var/run/reboot-required ]; then
  printf "\${execbar 14 echo 100}"
  printf "${font_standard}\${goto 0}\${voffset 6}${txt_align_center}\${color black}$mui_system_reboot\$color"
fi
echo "\${font}\${voffset -4}"

echo "${font_title}$mui_cpu_title \${hr 2}"
echo "${font_standard}\${execi 1000 grep model /proc/cpuinfo | cut -d : -f2 | tail -1 | sed 's/\s//'}"
cpu_temp="0"
if [[ "$gpu_temp" -ge "85" ]]; then
  cpu_color="red"
else
  cpu_color="light grey"
fi
echo "\${color lightgray}${font_standard}\${cpugraph cpu}\$color"
printf "${font_standard}$mui_cpu_cpu \${cpu cpu}%% \${goto 154}\${cpubar 6,140 cpu}"
printf "${font_standard}\${color $cpu_color}\${goto 296}\${execbar 9,20 echo "100"}\${color}"
echo "\${font Noto Mono:regular:size=6}\${goto 298}\${color black}\${hwmon 1 temp 2}°\$color"
gpu_brand=`lspci | grep ' VGA '`
if [[ "$gpu_brand" =~ "NVIDIA" ]]; then
  gpu_temp=`nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader`
  if [[ "$gpu_temp" -ge "85" ]]; then
    gpu_color="red"
  else
    gpu_color="light grey"
  fi
  printf "${font_standard}\${nvidia modelname}: \${nvidia gpuutil}%% \${goto 154}\${nvidiabar 6,140 gpuutil}"
  printf "${font_standard}\${color $gpu_color}\${goto 296}\${execbar 9,20 echo "100"}\${color}"
  echo "\${font Noto Mono:regular:size=6}\${goto 298}\${color black}\${nvidia temp}°\$color"
fi
HandBrake_process=`ps aux | grep HandBrakeCLI | sed '/grep/d'`
if [[ "$HandBrake_process" != "" ]]; then
  HandBrake_line=`cat "/opt/scripts/.convert2hdlight" | sed -n '1p'`
  if [[ "$HandBrake_line" != "Encodage terminé" ]] && [[ "$HandBrake_line" != "..." ]] && [[ "$HandBrake_line" != "" ]] && [[ "$HandBrake_line" != "Encodage en cours" ]]; then
    HandBrake_progress=`cat "/opt/scripts/.convert2hdlight" | sed -n '1p' | cut -d' ' -f2 | sed "s/(//" | sed "s/\..*//"`
    while [ "$HandBrake_progress" == "" ]; do
      HandBrake_progress=`cat "/opt/scripts/.convert2hdlight" | sed -n '1p' | cut -d' ' -f2 | sed "s/(//" | sed "s/\..*//"`
    done
    HandBrake_progress_human=`printf '%d' $HandBrake_progress`
    HandBrake_ETA=`cat "/opt/scripts/.convert2hdlight" | sed -n '7p'`
    while [ "$HandBrake_ETA" == "" ]; do
      HandBrake_ETA=`cat "/opt/scripts/.convert2hdlight" | sed -n '7p'`
    done
    HandBrake_categorie=`cat "/opt/scripts/.convert2hdlight" | sed -n '5p'`
    while [ "$HandBrake_categorie" == "" ]; do
      HandBrake_categorie=`cat "/opt/scripts/.convert2hdlight" | sed -n '5p'`
    done
    HandBrake_file=`cat "/opt/scripts/.convert2hdlight" | sed -n '6p'`
    while [ "$HandBrake_file" == "" ]; do
      HandBrake_file=`cat "/opt/scripts/.convert2hdlight" | sed -n '6p'`
    done
    echo "${font_standard}$mui_cpu_handbrake $(printf "%3d" $HandBrake_progress_human)% \${execbar 6 echo $HandBrake_progress_human}"
    echo "${font_standard}$mui_cpu_handbrake_ETA$txt_align_right$HandBrake_ETA"
    if [[ "$HandBrake_categorie" == "Film" ]]; then
      echo "${font_standard}$mui_cpu_handbrake_film$txt_align_right${HandBrake_file:0:40}"
    else
      echo "${font_standard}$mui_cpu_handbrake_serie$txt_align_right${HandBrake_file:0:40}"
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
    if [[ "$user_pass" != "" ]]; then
      disk_interface=`udevadm info --query=all --name=$drive | grep ID_BUS`
      if [[ "$disk_interface" =~ "usb" ]]; then
        disk_temp=""
        disk_color="light blue"
      else
        disk_temp=`echo $user_pass | sudo -kS hddtemp $drive 2>/dev/null | awk '{ print $NF }' | sed 's/C//'`
        disk_temp_number=` echo $disk_temp | sed 's/\°//'`
        if [[ "$disk_temp_number" -ge "45" ]]; then
          disk_color="red"
        else
          disk_color="light grey"
        fi
      fi
      printf "${font_standard}${mount_point:0:20} ${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%%]\${execbar 6,88 echo $disk_usage}"
      printf "${font_standard}\${color $disk_color}\${goto 296}\${execbar 9,20 echo "100"}\${color}"
      echo "\${font Noto Mono:regular:size=6}\${goto 298}\${color black}$disk_temp\$color"
    else
      echo ${font_standard}${mount_point:0:18} ${txt_align_right}\${goto 120}"["$(printf "%04s" $disk_free_human)" / "$(printf "%03d" $disk_usage)"%] "\${execbar 6,112 echo $disk_usage}
    fi
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
echo "${font_standard}$mui_network_ip_public $txt_align_right\${execi 1000  wget -q -O- http://ipecho.net/plain}"
fi
echo "${font_standard}$mui_network_down \${downspeed $net_adapter}  ${txt_align_right}$mui_network_up \${upspeed $net_adapter}"
echo "\${color lightgray}\${downspeedgraph $net_adapter 40,150 } ${txt_align_right}\${upspeedgraph $net_adapter 40,150 }\$color"
echo "\${font}\${voffset -4}"

transmission_state=`systemctl show -p SubState --value transmission-daemon`
if [[ "$transmission_state" != "dead" ]]; then
  echo "${font_title}$mui_transmission_title \${hr 2}"
  echo "${font_standard}$mui_transmission_state ${txt_align_right}\${execi 5 systemctl is-active transmission-daemon}"
  if [[ "$transmission_ip" != "" ]] && [[ "$transmission_port" != "" ]] && [[ "$transmission_login" != "" ]] && [[ "$transmission_password" != "" ]]; then
    test_transmission=`transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l 2>/dev/null`
    if [[ "$test_transmission" != "" ]]; then
      transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l >transm.log
      transmission_queue=`cat transm.log | sed '/^ID/d' | sed '/^Sum:/d' | sed '/ Done /d' | wc -l`
      echo "${font_standard}$mui_transmission_queue ${txt_align_right}$transmission_queue "
      transmission_down=`cat transm.log | grep Sum: | awk '{ print $NF }' | sed "s/\..*//"`
      transmission_down_human=`numfmt --to=iec-i --from-unit=1024 --suffix=B $transmission_down`
      transmission_up=`cat transm.log | grep Sum: | awk '{ print $(NF-1) }' | sed "s/\..*//"`
      transmission_up_human=`numfmt --to=iec-i --from-unit=1024 --suffix=B $transmission_up`
      echo "${font_standard}$mui_transmission_down $transmission_down_human ${txt_align_right}$mui_transmission_up $transmission_up_human"
      rm transm.log
    else
      printf "\${execbar 14 echo 100}"
      printf "${font_standard}\${goto 0}\${voffset 6}${txt_align_center}\${color black}$mui_transmission_error\$color"
    fi
  else
    ## was set to settings2 instead of settings to disable
    if [[ -f "/etc/transmission-deamon/settings2.json" ]]; then
      transmission_port=`echo $user_pass | sudo -kS cat /etc/transmission-daemon/settings.json 2>/dev/null | jq -r '."rpc-port"'`
      transmission_ip="localhost"
      echo $user_pass | sudo -kS cat /etc/transmission-daemon/settings.json 2>/dev/null | jq -r '."rpc-username"' | sed 's/./\\&/g' >temp_tr.log
      transmission_login=`cat temp_tr.log`
      rm temp_tr.log
      echo $user_pass | sudo -kS cat /etc/transmission-daemon/settings.json 2>/dev/null | jq -r '."rpc-password"' | sed 's/./\\&/g' >temp_tr.log
      transmission_password=`cat temp_tr.log`
      rm temp_tr.log
      echo "${font_standard}$mui_transmission_queue ${txt_align_right}\${exec transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l 2>/dev/null | sed '/^ID/d' | sed '/^Sum:/d' | sed '/ Done /d' | wc -l} "
      transmission_down=`transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l 2>/dev/null | grep Sum: | awk '{ print $5 }' | sed "s/\..*//"`
      transmission_down_human=`numfmt --to=iec-i --from-unit=1024 --suffix=B $transmission_down`
      transmission_up=`transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l 2>/dev/null | grep Sum: | awk '{ print $4 }' | sed "s/\..*//"`
      transmission_up_human=`numfmt --to=iec-i --from-unit=1024 --suffix=B $transmission_up`
      echo "${font_standard}$mui_transmission_down $transmission_down_human ${txt_align_right}$mui_transmission_up $transmission_up_human"
    else
      echo ""
      printf "\${execbar 14 echo 100}"
      printf "${font_standard}\${goto 0}\${voffset 6}${txt_align_center}\${color black}$mui_transmission_error\$color"
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
        echo -e "$font_extra\u25CF $font_standard${plex_serie:0:22} ("$plex_season"x$(printf "%02d" $plex_episode)) $txt_align_right${plex_user:0:15}"
      else
        echo -e "$font_extra\u25C9 $font_standard${plex_serie:0:22} ("$plex_season"x$(printf "%02d" $plex_episode)) $txt_align_right${plex_user:0:15}"
      fi
    else
      plex_title=`echo $plex_stream | sed 's/ title="/|/g' | cut -d'|' -f2 | sed 's/".*//'`
      if [[ "$plex_transcode" == "transcode" ]]; then
        echo -e "$font_extra\u25CF $font_standard${plex_title:0:30} $txt_align_right${plex_user:0:16}"
      else
        echo -e "$font_extra\u25C9 $font_standard${plex_title:0:30} $txt_align_right${plex_user:0:16}"
      fi
    fi
    plex_bar_progress=$(($plex_inprogressms*100/$plex_durationms))
    echo $font_standard$plex_inprogress" / "$plex_duration  \${execbar echo $plex_bar_progress}
    let num=$num+1
  done
else
  echo "${font_title}$mui_plex_title \${hr 2}"
    echo ""
    printf "\${execbar 14 echo 100}"
    printf "${font_standard}\${voffset -1}\${goto 0 }${txt_align_center}\${color black}$mui_plex_error\$color"
fi
