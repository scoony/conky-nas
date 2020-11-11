#!/bin/bash
 
## CONFIG
#########
font_title="\${font Ubuntu:bold:size=10}"
font_standard="\${font Noto Mono:normal:size=8}"
font_extra="\${font sans-serif:normal:size=8}"
txt_align_right="\${alignr}"
txt_align_center="\${alignc}"
font_awesome_font="FontAwesome:regular:size=16"
font_awesome_system="\uf17c"
font_awesome_cpu="\uf06d"
font_awesome_memory="\uf2db"
font_awesome_diskusage="\uf0a0"
font_awesome_network_secured="\uf21b"
font_awesome_network="\uf6ff"
font_awesome_transmission="\uf019"
font_awesome_plex="\uf008"
plex_check="yes"
plex_stream_state_play="\${font FontAwesome:regular:size=8}\uF04B$font_standard"
plex_stream_state_pause="\${font FontAwesome:regular:size=8}\uF04C$font_standard"
font_awesome_service="\uf085"
font_awesome_pushover="\uf3cd"
font_awesome_updater="\uf021"
user_pass=""
user_avatar=""
transmission_check="yes"
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


#### Autoupdater

if ! pgrep -x "conky-update" > /dev/null
then
  nohup ~/.conky/conky-update > /dev/null 2>/dev/null &
else
  printf "\${font FontAwesome:regular:size=8}\${alignr}$(echo -e $font_awesome_updater)\${font}"
fi


#### Functions

##charwidth() {
##  set "$(printf '...%s\b\b...\n' "$1" | col -b)"
##  echo "$((${#1} - 4))"
##}


#### Avatar, date & clock Block

avatar_path=`echo ~`
user_avatar_path=${user_avatar//\~/$avatar_path}
if [[ -f "$user_avatar_path" ]]; then
  if [[ "$user_avatar_location" != "" ]]; then
    echo "\${image $user_avatar $user_avatar_location}"
  else
    echo "\${image $user_avatar -p 238,3 -s 60x60 -f 86400}"
  fi
else
  echo ""
fi
echo "\${voffset -10}${font_time}\${alignc}\${time %H:%M}\${font}"
echo "${font_date}${txt_align_center}\${time %A %d %B}"
if [[ "$user_town" != "" ]]; then
  echo "${txt_align_center}${font_weather}\${exec curl --silent wttr.in/$user_town?format=2}${font_standard}"
fi
echo "\${font}\${voffset -4}"


#### Pushover Block

if [[ "$push_activation" == "yes" ]]; then
  ## Function to push
  push-message() {
  if [[ "$DISPLAY" == ":0" ]] || [[ "$DISPLAY" == ":1" ]]; then
    push_title=$1
    push_content=$2
    if [ -n "$push_target" ]; then
      curl -s \
        --form-string "token=$push_token_app" \
        --form-string "user=$push_target" \
        --form-string "title=$push_title" \
        --form-string "message=$push_content" \
        --form-string "html=1" \
        --form-string "priority=0" \
        https://api.pushover.net/1/messages.json > /dev/null
    fi
  fi
  }
  if [[ ! -d ~/.conky/pushover ]]; then mkdir -p ~/.conky/pushover; fi
  if [[ "$push_token_app" == "" ]] || [[ "$push_target" == "" ]]; then
    echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_pushover")\${font} ${font_title}$mui_pushover_title \${hr 2}"
    echo ""
    echo "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_pushover_error\$color"
    echo "\${font}\${voffset -4}"
  fi
fi


#### System Block

echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_system")\${font}\${goto 35} ${font_title}$mui_system_title \${hr 2}"
hdd_total=`df --total 2>/dev/null | sed -e '$!d' | awk '{ print $2 }' | numfmt --from-unit=1024 --to=si --suffix=B`
hdd_free_total=`df --total 2>/dev/null | sed -e '$!d' | awk '{ print $4 }' | numfmt --from-unit=1024 --to=si --suffix=B`
echo "${font_standard}$mui_system_host$txt_align_right\$nodename"
echo "${font_standard}$mui_system_uptime$txt_align_right\$uptime"
echo "${font_standard}$mui_system_hdd_total$txt_align_right$hdd_total"
echo "${font_standard}$mui_system_hdd_free_total$txt_align_right$hdd_free_total"
if [ -f /var/run/reboot-required ]; then
  echo "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset 6}${txt_align_center}\${color black}$mui_system_reboot\$color"
fi
echo "\${font}\${voffset -4}"


#### Services Block

if [[ "$services_list" != "" ]]; then
  echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_service")\${font}\${goto 35} ${font_title}$mui_services_title \${hr 2}"
  services_list_sorted=$(echo $services_list | xargs -n1 | sort -u | xargs)
  service_alert="0"
  for myservice in $services_list_sorted ; do
    service_mystate=`systemctl show -p SubState --value $myservice`
    if [[ "$service_mystate" == "running" ]]; then
      service_color=""
      if [[ -f ~/.conky/pushover/$myservice ]]; then
        rm ~/.conky/pushover/$myservice
        myservice_message="[ $myservice ] $mui_pushover_service_restarted"
        push-message "Conky" "$myservice_message"
      fi
    else
      service_color="red"
      service_alert="1"
      echo "${font_standard}$myservice:${txt_align_right}\${color $service_color}\${execi 5 systemctl is-active $myservice}\$color"
      if [[ ! -f ~/.conky/pushover/$myservice ]]; then
        touch ~/.conky/pushover/$myservice
        if [[ "$user_pass" != "" ]]; then
          myservice_message="[ $myservice ] $mui_pushover_service_restart"
          echo $user_pass | sudo -kS service $myservice restart
        else
          myservice_message="[ $myservice ] $mui_pushover_service"
        fi
        push-message "Conky" "$myservice_message"
      fi
    fi
  done
  if [[ "$service_alert" == "0" ]]; then
    echo "${font_standard}$mui_services_ok"
  fi
  echo "\${font}\${voffset -4}"
fi


#### CPU Block

echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_cpu")\${font}\${goto 35} ${font_title}$mui_cpu_title \${hr 2}"
echo "${font_standard}\${execi 1000 grep model /proc/cpuinfo | cut -d : -f2 | tail -1 | sed 's/\s//'}"
cpu_temp=`paste <(cat /sys/class/thermal/thermal_zone*/type) <(cat /sys/class/thermal/thermal_zone*/temp) | column -s $'\t' -t | sed 's/\(.\)..$/.\1°C/' | grep "x86_pkg_temp" | awk '{ print $2 }' | sed 's/\°C//' | sed 's/\..*//'`
cpu_num="1"
for cpu_number in $cpu_temp ; do
  if [[ "$cpu_number" -ge "85" ]]; then
    cpu_color="red"
  else
    cpu_color="light grey"
  fi
  echo "\${color lightgray}${font_standard}\${cpugraph cpu}\$color"
  echo "${font_standard}$mui_cpu_cpu\${goto 130}\${cpu cpu$cpu_num}% \${goto 154}\${voffset 1}\${cpubar 6,140 cpu$cpu_num}${font_standard}\${color $cpu_color}\${goto 296}\${execbar 8,20 echo "100"}\${color}\${font Noto Mono:regular:size=6}\${goto 300}\${voffset -1}\${color black}${cpu_number:0:2}°\$color"
  cpu_num=$((cpu_num+1))
done
gpu_brand=`lspci | grep ' VGA '`
if [[ "$gpu_brand" =~ "NVIDIA" ]]; then
  gpu_temp=`nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader`
  if [[ "$gpu_temp" -ge "85" ]]; then
    gpu_color="red"
  else
    gpu_color="light grey"
  fi
  echo "${font_standard}\${nvidia modelname}:\${goto 130}\${nvidia gpuutil}% \${goto 154}\${voffset 1}\${nvidiabar 6,140 gpuutil}${font_standard}\${color $gpu_color}\${goto 296}\${execbar 8,20 echo "100"}\${color}\${font Noto Mono:regular:size=6}\${goto 300}\${voffset -1}\${color black}\${nvidia temp}°\$color"
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
    echo "${font_standard}$mui_cpu_handbrake\${goto 124}$(printf "%3d" $HandBrake_progress_human)%\${goto 154}\${voffset 1}\${execbar 6 echo $HandBrake_progress_human}"
    echo "${font_standard}$mui_cpu_handbrake_ETA$txt_align_right$HandBrake_ETA"
    if [[ "$HandBrake_categorie" == "Film" ]]; then
      echo "${font_standard}$mui_cpu_handbrake_film$txt_align_right${HandBrake_file:0:40}"
    else
      echo "${font_standard}$mui_cpu_handbrake_serie$txt_align_right${HandBrake_file:0:40}"
    fi
  fi
fi
echo "\${font}\${voffset -4}"


#### Memory Block

echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_memory")\${font}\${goto 35} ${font_title}$mui_memory_title \${hr 2}"
echo "${font_standard}$mui_memory_ram $txt_align_center \$mem / \$memmax $txt_align_right \$memperc%"
echo "${font_standard}\$membar"
echo "${font_standard}$mui_memory_swap $txt_align_center \${swap} / \${swapmax} $txt_align_right \${swapperc}%"
echo "${font_standard}\${swapbar}"
echo "\${font}\${voffset -4}"


#### DiskUsage Block

echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_diskusage")\${font}\${goto 35} ${font_title}$mui_diskusage_title \${hr 2}"
drives=`ls /dev/mmcblk[1-9]p[1-9] /dev/sd*[1-9] 2>/dev/null`
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
      disk_support=`udevadm info --query=all --name=$drive | grep ID_DRIVE_FLASH_SD`
      if [[ "$disk_interface" =~ "usb" ]] || [[ "$disk_support" != "" ]]; then
        disk_temp=""
        disk_color="light blue"
      else
        disk_temp=`echo $user_pass | sudo -kS hddtemp $drive 2>/dev/null | awk '{ print $NF }' | sed 's/°C//'`
        if [[ "$disk_temp" -ge "45" ]]; then
          disk_color="red"
        else
          disk_color="light grey"
        fi
      fi
      drive_short=`basename $drive`
      if [[ ! -d ~/.conky/SMART ]]; then
        mkdir ~/.conky/SMART
      fi
      printf "\${execi 3600 echo $user_pass | sudo -kS smartctl -a $drive > ~/.conky/SMART/$drive_short.log }"
      smart_enabled=`cat ~/.conky/SMART/$drive_short.log | grep "SMART support is:" | awk '{print $NF}' | tail -1`
      smart_status=`cat ~/.conky/SMART/$drive_short.log | grep "SMART overall-health" | awk '{print $NF}'`
      smart_offline_uncorrectable=`cat ~/.conky/SMART/$drive_short.log | grep -i "Offline_Uncorrectable" | awk '{print $NF}'`
      if [[ "$smart_offline_uncorrectable" == "" ]]; then
        smart_offline_uncorrectable=`cat ~/.conky/SMART/$drive_short.log | grep -i "Reallocated_Sector_Ct" | awk '{print $NF}'`
      fi
      if [[ "$smart_enabled" == "Enabled" ]]; then
        if [[ "$smart_status" == "PASSED" ]]; then
          if [[ "$smart_offline_uncorrectable" == "0" ]]; then
            smart_glyph="\uf0c8"
            smart_color="light green"
          else
            smart_glyph="\uf0c8"
            smart_color="orange"
            last_smart_error=`cat ~/.conky/SMART/$drive_short.error 2>/dev/null`
            if [[ "$smart_offline_uncorrectable" != "$last_smart_error" ]]; then
              smart_serial=`cat ~/.conky/SMART/$drive_short.log | grep "Serial Number:" | awk '{print $NF}' | tail -1`
              smart_size=`df -Hl $drive | awk '{ print $2 }' | tail -1`
              smart_age=`cat ~/.conky/SMART/$drive_short.log | grep -i "Power_On_Hours" | awk '{print $NF}' | tail -1 | awk '{print $1/3}'`
              push_content=`echo -e "[ <b>SMART</b> ] $mui_smart_error_title\n\n<b>$mui_smart_error_main</b> $drive\n<b>$mui_smart_error_serial</b> $smart_serial\n<b>$mui_smart_error_size</b> $smart_size\n<b>$mui_smart_error_age</b> $smart_age\n<b>$mui_smart_error_errors</b> $smart_offline_uncorrectable"`
              push-message "Conky" "$push_content"
            fi
            echo $smart_offline_uncorrectable > ~/.conky/SMART/$drive_short.error
          fi
        else
          smart_glyph="\uf046"
          smart_color="red"
        fi
      else
        smart_glyph="\u0020"
        smart_color=""
      fi
      if [[ "$disk_temp" != "" ]]; then
        echo -e "\${offset -5}\${voffset 3}\${font FontAwesome:regular:size=5}\${color $smart_color}$smart_glyph\${color}\${voffset -3}\${goto 6}${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,88 echo $disk_usage}${font_standard}\${color $disk_color}\${goto 296}\${execbar 8,20 echo "100"}\${color}\${font Noto Mono:regular:size=6}\${goto 300}\${voffset -1}\${color black}${disk_temp:0:2}°\$color"
      else
        echo -e "\${offset -5}\${voffset 3}\${font FontAwesome:regular:size=5}\${color $smart_color}$smart_glyph\${color}\${voffset -3}\${goto 6}${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,88 echo $disk_usage}${font_standard}\${color $disk_color}\${goto 296}\${execbar 8,20 echo "100"}\${color}\${font Noto Mono:regular:size=6}\${goto 298}\${voffset -1}\${color black}\$color"
      fi
    else
      disk_interface=`udevadm info --query=all --name=$drive | grep ID_BUS`
      disk_support=`udevadm info --query=all --name=$drive | grep ID_DRIVE_FLASH_SD`
      if [[ "$disk_interface" =~ "usb" ]] || [[ "$disk_support" != "" ]]; then
        disk_color="light blue"
      else
        disk_color="light grey"
      fi
      echo "${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,110 echo $disk_usage}"
    fi
  fi
done
echo "\${font}\${voffset -4}"


#### Network Block

vpn_detected=`ifconfig | grep "tun[0-9]"`
if [[ "$vpn_detected" != "" ]]; then
  echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_network_secured")\${font}\${goto 35} ${font_title}$mui_network_title_secured \${hr 2}"
else
  echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_network")\${font}\${goto 35} ${font_title}$mui_network_title \${hr 2}"
fi
net_adapter=`ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//"`
if [[ "$net_adapter" == "wlan0" ]]; then
  echo "${font_standard}$mui_network_adapter $txt_align_right $net_adapter (\${wireless_essid $net_adapter})"
else
  net_adapter_speed=`cat /sys/class/net/$net_adapter/speed`
  echo "${font_standard}$mui_network_adapter $txt_align_right $net_adapter ($net_adapter_speed Mbps)"
fi
net_ip_public=`dig -4 +short myip.opendns.com @resolver1.opendns.com`
if [[ "$vpn_detected" != "" ]]; then
  echo "${font_standard}$mui_network_vpn $txt_align_right\${execi 5 systemctl is-active $vpn_service}"
  net_ip_box=`dig -b $(hostname -I | cut -d' ' -f1) +short myip.opendns.com @resolver1.opendns.com`
  echo "${font_standard}$mui_network_ip_public $txt_align_right$net_ip_public"
  echo "${font_standard}$mui_network_ip_box $txt_align_right$net_ip_box"
  if [[ "$net_ip_box" == "$net_ip_public" ]]; then
    if [[ ! -f ~/.conky/pushover/vpn_error ]]; then
      touch ~/.conky/pushover/vpn_error
      if [[ "$user_pass" != "" ]]; then
        mynetwork_message="[ VPN ] $mui_network_vpn_restart"
        echo $user_pass | sudo -kS service $vpn_service restart
      else
        mynetwork_message="[ VPN ] $mui_network_vpn_ko"
      fi
      push-message "Conky" "$mynetwork_message"
    fi
  else
    if [[ -f ~/.conky/pushover/vpn_error ]]; then
      rm ~/.conky/pushover/vpn_error
    fi
  fi
else
  echo "${font_standard}$mui_network_ip_public $txt_align_right$net_ip_public"
fi
echo "${font_standard}$mui_network_down \${downspeed $net_adapter}  ${txt_align_right}$mui_network_up \${upspeed $net_adapter}"
echo "\${color lightgray}\${downspeedgraph $net_adapter 25,150 } ${txt_align_right}\${upspeedgraph $net_adapter 25,150 }\$color"
echo "\${font}\${voffset -4}"


#### Transmission Block

if [[ "$transmission_check" == "yes" ]]; then
  transmission_state=`systemctl show -p SubState --value transmission-daemon`
  if [[ "$transmission_state" != "dead" ]]; then
    echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_transmission")\${font}\${goto 35} ${font_title}$mui_transmission_title \${hr 2}"
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
        echo ""
        echo "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_transmission_error\$color"
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
        echo "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_transmission_error\$color"
      fi
    fi
    echo "\${font}\${voffset -4}"
  else
    if [[ "$transmission_ip" != "" ]] && [[ "$transmission_port" != "" ]] && [[ "$transmission_login" != "" ]] && [[ "$transmission_password" != "" ]]; then
      echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_transmission")\${font} ${font_title}$mui_transmission_title \${hr 2}"
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
        echo ""
        echo "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_transmission_error\$color"
      fi
      echo "\${font}\${voffset -4}"
    fi
  fi
fi

#### Plex Block

if [[ "$plex_check" == "yes" ]]; then
  plex_state=`systemctl show -p SubState --value plexmediaserver`
  if [[ "$plex_state" != "dead" ]] || [[( "$plex_ip" != "" ) && ( "$plex_port" != "" ) && ( "$plex_token" != "" )]]; then
    echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_plex")\${font}\${goto 35} ${font_title}$mui_plex_title \${hr 2}"
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
      plex_stream=`echo $plex_xml | xmllint --format - | sed ':a;N;$!ba;s/\n/ /g' | sed "s/<\/Video> /|/g" | sed "s/<\/Track> /|/g" | cut -d'|' -f$num`
      plex_user=`echo $plex_stream | grep -Po '(?<=<User id)[^>]*' | sed 's/ title="/|/g' | cut -d'|' -f2 | sed 's/".*//' | cut -d@ -f1`
      plex_transcode=`echo $plex_stream | sed 's/.* videoDecision="//' | sed 's/".*//'`
      let plex_inprogressms=`echo $plex_stream | sed 's/.* viewOffset="//' | sed 's/".*//'`
      plex_inprogress=`printf '%d:%02d:%02d\n' $(($plex_inprogressms/1000/3600)) $(($plex_inprogressms/1000%3600/60)) $(($plex_inprogressms/1000%60))`
      let plex_durationms=`echo $plex_stream | sed 's/.* duration="//' | sed 's/".*//'`
      plex_duration=`printf '%d:%02d:%02d\n' $(($plex_durationms/1000/3600)) $(($plex_durationms/1000%3600/60)) $(($plex_durationms/1000%60))`
      plex_state=`echo $plex_stream | sed 's/.* state="//' | sed 's/".*//'`
      if [[ "$plex_state" == "playing" ]]; then
        plex_state_human="$plex_stream_state_play "
      else
        if [[ "$plex_state" == "paused" ]]; then
          plex_state_human="$plex_stream_state_pause "
        else
          plex_state_human=""
        fi
      fi
      plex_checkmusic=`echo $plex_stream | grep ' type="track"'`
      if [[ "$plex_checkmusic" != "" ]]; then
          plex_artiste=`echo $plex_stream | sed 's/.* originalTitle="//' | sed 's/".*//'`
          plex_song=`echo $plex_stream | sed 's/<Media .*//' | sed 's/.* title="//' | sed 's/".*//'`
          echo -e "$font_extra\u25CF $font_standard$plex_artiste - $plex_song $txt_align_right${plex_user:0:15}"

      else
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
      fi
      plex_bar_progress=$(($plex_inprogressms*100/$plex_durationms))
      echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress}
      let num=$num+1
    done
  else
    echo "\${font ${font_awesome_font}}$(echo -e "$font_awesome_plex")\${font}\${goto 35} ${font_title}$mui_plex_title \${hr 2}"
    echo ""
    echo "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_plex_error\$color"
  fi
fi
