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
font_awesome_ups_full="\uf240"
font_awesome_ups_three_quarter="\uf241"
font_awesome_ups_half="\uf242"
font_awesome_ups_quarter="\uf243"
font_awesome_ups_empty="\uf244"
font_awesome_cpu="\uf06d"
font_awesome_memory="\uf2db"
font_awesome_diskusage="\uf0a0"
font_awesome_network_secured="\uf21b"
font_awesome_network="\uf6ff"
font_awesome_network_wifi="\${font FontAwesome:regular:size=8}\uf1eb$font_standard"
font_awesome_connexion="\uf0ec"
font_awesome_transmission="\uf019"
font_awesome_scripts="\uf085"
font_awesome_scripts_ok="\${font FontAwesome:regular:size=8}\uf00c$font_standard"
font_awesome_scripts_ko="\${font FontAwesome:regular:size=8}\uf00d$font_standard"
font_awesome_plex="\uf008"
bar="\${voffset -2}\${font Ubuntu Mono Regular:regular:size=6}\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588$font_standard"
plex_check="no"
plex_stream_state_play="\${font FontAwesome:regular:size=8}\uF04B$font_standard"
plex_stream_state_pause="\${font FontAwesome:regular:size=8}\uF04C$font_standard"
plex_stream_state_buffer="\${font FontAwesome:regular:size=8}\uF252$font_standard"
font_awesome_service="\uf085"
font_awesome_pushover="\uf3cd"
font_awesome_updater="\uf021"
user_pass=""
user_avatar=""
transmission_check="no"
transmission_login=""
transmission_password=""
transmission_ip=""
transmission_port=""
plex_ip=""
plex_port=""
plex_token=""


## DONT EDIT AFTER THIS
#######################

if [[ ! -d ~/.conky/Temp ]]; then
  mkdir ~/.conky/Temp
fi

## Cleaning for smart-status

if [[ $(date +"%H:%M") == "00:00" ]]; then
  rm ~/.conky/transmission-done
fi

## Check local language and apply MUI

os_language=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
if [[ -f ~/.conky/MUI/$os_language.lang ]]; then
  script_language="~/.conky/MUI/$os_language.lang"
  source ~/.conky/MUI/$os_language.lang
else
  script_language="~/.conky/MUI/en.lang"
  source ~/.conky/MUI/en.lang
fi


## Load config (if exist)

if [[ -f ~/.conky/conky-nas.conf ]]; then
  source ~/.conky/conky-nas.conf
fi


#### Autoupdater

if ! pgrep -x "conky-update" > /dev/null
then
  nohup ~/.conky/conky-update > /dev/null 2>/dev/null &
else
  printf "\${font FontAwesome:regular:size=8}\${alignr}$(echo -e $font_awesome_updater)\${font}"
fi


#### Detect network adapter

net_adapter=`ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//" | sed ':a;N;$!ba;s/\n/ /g'`


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
echo -e "\${voffset -10}${font_time}\${alignc}\${time %H:%M}\${font}"
echo -e "${font_date}${txt_align_center}\${time %A %d %B}"
if [[ "$net_adapter" != "" ]]; then
  if [[ "$user_town" != "" ]]; then
    echo -e "${txt_align_center}${font_weather}\${exec curl --silent wttr.in/$user_town?format=2}${font_standard}"
  fi
fi
echo "\${font}\${voffset -4}"


#### Pushover Block

if [[ "$push_activation" == "yes" ]]; then
  ## Function to push
  push-message() {
  if [[ "$net_adapter" != "" ]]; then
    if [[ "$DISPLAY" == ":0" ]] || [[ "$DISPLAY" == ":1" ]]; then
      push_priority=$1
      push_title=$2
      push_content=$3
      push_token=$4
      if [ -n "$push_target" ]; then
        curl -s \
          --form-string "token=$push_token" \
          --form-string "user=$push_target" \
          --form-string "title=$push_title" \
          --form-string "message=$push_content" \
          --form-string "html=1" \
          --form-string "priority=$push_priority" \
          https://api.pushover.net/1/messages.json > /dev/null
      fi
    fi
  fi
  }
  if [[ ! -d ~/.conky/pushover ]]; then mkdir -p ~/.conky/pushover; fi
  if [[ "$push_token_app" == "" ]] || [[ "$push_target" == "" ]]; then
    echo -e "\${font ${font_awesome_font}}$font_awesome_pushover\${font} ${font_title}$mui_pushover_title \${hr 2}"
    echo ""
    echo -e "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_pushover_error\$color"
    echo "\${font}\${voffset -4}"
  fi
fi


#### System Block

time1=`date +%s`
echo -e "\${font ${font_awesome_font}}$font_awesome_system\${font}\${goto 35} ${font_title}$mui_system_title \${hr 2}"
hdd_total=`df -l --total 2>/dev/null | sed -e '$!d' | awk '{ print $2 }' | numfmt --from-unit=1024 --to=si --suffix=B`
#hdd_total=`df 2>/dev/null | sed '/\/\//d' | sed -e '1d' | awk '{print (total +=$2)}' | numfmt --from-unit=1024 --to=si --suffix=B | sed -e '$!d'`
hdd_free_total=`df -l --total 2>/dev/null | sed -e '$!d' | awk '{ print $4 }' | numfmt --from-unit=1024 --to=si --suffix=B`
#hdd_free_total=`df 2>/dev/null | sed '/\/\//d' | sed -e '1d' | awk '{print (total +=$4)}' | numfmt --from-unit=1024 --to=si --suffix=B | sed -e '$!d'`
echo -e "${font_standard}$mui_system_host$txt_align_right\$nodename"
echo -e "${font_standard}$mui_system_uptime$txt_align_right\$uptime"
#echo -e "${font_standard}$mui_system_hdd_total$txt_align_right$hdd_total"
#echo -e "${font_standard}$mui_system_hdd_free_total$txt_align_right$hdd_free_total"
echo -e "${font_standard}$mui_system_hdd_total$txt_align_right$hdd_free_total / $hdd_total"
power_supply=`acpi -b 2>/dev/null | sed '/rate information unavailable/d'`
if [[ "$power_supply" != "" ]]; then
  battery_state=`acpi -b | awk "{print $1}" | sed '/rate information unavailable/d' | sed 's/\([^:]*\): \([^,]*\), \([0-9]*\)%.*/\2/' | sed -n '1p'`
  battery_charge=`acpi -b | awk "{print $1}" | sed '/rate information unavailable/d' | sed 's/\([^:]*\): \([^,]*\), \([0-9]*\)%.*/\3/' | sed -n '1p'`
  if [[ $battery_charge -lt 10 ]]; then
    battery_charge_color="red"
  else
    if [[ $battery_charge -lt 40 ]]; then
      battery_charge_color="orange"
    else
      if [[ $battery_charge -lt 80 ]]; then
        battery_charge_color="white"
      else
        battery_charge_color="green"
      fi
    fi
  fi
  if [[ "$battery_state" == "Full" ]] || [[ "$battery_state" == "Unknown" ]]; then
    echo -e "${font_standard}$mui_system_charge_full\${goto 124}\${color $battery_charge_color}$(printf "%3d" $battery_charge)%\$color\${goto 154}\${voffset 1}\${execbar 6 echo $battery_charge}"
  else
    battery_timeleft=`acpi -b | awk "{print $1}" | sed '/rate information unavailable/d' | sed 's/\([^:]*\): \([^,]*\), \([0-9]*\)%, \([0-2][0-9]:[0-5][0-9]:[0-5][0-9]\).*/\4/' | sed -n '1p'`  
    if [[ "$battery_state" == "Discharging" ]]; then
      echo -e "${font_standard}$mui_system_charge_offline\${goto 124}\${color $battery_charge_color}$(printf "%3d" $battery_charge)%\$color\${goto 154}\${voffset 1}\${execbar 6 echo $battery_charge}"
      echo -e "${font_standard}$mui_system_charge_remaining$txt_align_right$battery_timeleft"
    else
      echo -e "${font_standard}$mui_system_charge_online\${goto 124}\${color $battery_charge_color}$(printf "%3d" $battery_charge)%\$color\${goto 154}\${voffset 1}\${execbar 6 echo $battery_charge}"
      echo -e "${font_standard}$mui_system_charge_until_charged$txt_align_right$battery_timeleft"
	  fi
  fi
fi
if [ -f /var/run/reboot-required ]; then
  echo -e "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset 6}${txt_align_center}\${color black}$mui_system_reboot\$color"
fi
time2=`date +%s`
duration_block=$(($time2-$time1))
if [[ "$debug" == "yes" ]]; then
  if [[ $duration_block -lt 60 ]]; then
    echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Ss)"
  else
    echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Mm:%Ss)"
  fi
fi
echo "\${font}\${voffset -4}"


#### UPS(s) Block

if [[ "$ups_check" == "yes" ]]; then
  printf "\${execi 15 upsc $ups_user@$ups_ip 2>/dev/null > ~/.conky/Temp/ups.log }"
#  upsc $ups_user@$ups_ip 2>/dev/null > ~/.conky/Temp/ups.log
#  ups_brand=`cat ~/.conky/Temp/ups.log 2>/dev/null | grep ups.mfr: | sed 's/.*: //g'`
#  ups_model=`cat ~/.conky/Temp/ups.log 2>/dev/null | grep ups.model: | sed 's/.*: //g'`
  ups_charge=`cat ~/.conky/Temp/ups.log 2>/dev/null | grep battery.charge: | awk '{print $NF}'`
  ups_load=`cat ~/.conky/Temp/ups.log 2>/dev/null | grep ups.load: | awk '{print $NF}'`
  ups_power=`cat ~/.conky/Temp/ups.log 2>/dev/null | grep ups.power: | awk '{print $NF}'`
  ups_power_nominal=`cat ~/.conky/Temp/ups.log 2>/dev/null | grep ups.power.nominal: | awk '{print $NF}'`
  ups_status=`cat ~/.conky/Temp/ups.log 2>/dev/null | grep ups.status: | awk '{print $NF}'`
  if [[ $ups_charge -gt 75 ]]; then
    echo -e "\${font ${font_awesome_font}}$font_awesome_ups_full\${font}\${goto 35} ${font_title}$mui_ups_title \${hr 2}"
  else
    if [[ $ups_charge -gt 50 ]]; then
      echo -e "\${font ${font_awesome_font}}$font_awesome_ups_three_quarter\${font}\${goto 35} ${font_title}$mui_ups_title \${hr 2}"
    else
      if [[ $ups_charge -gt 25 ]]; then
        echo -e "\${font ${font_awesome_font}}$font_awesome_ups_half\${font}\${goto 35} ${font_title}$mui_ups_title \${hr 2}"
      else
        echo -e "\${font ${font_awesome_font}}\${color red}$font_awesome_ups_quarter\$color\${font}\${goto 35} ${font_title}$mui_ups_title \${hr 2}"
      fi
    fi
  fi
#  echo -e "${font_standard}$ups_brand $ups_model"
  if [[ "$ups_status" != "OL" ]]; then
    ups_runtime=`cat ~/.conky/Temp/ups.log 2>/dev/null | grep battery.runtime: | awk '{print $NF}'`
    echo -e "${font_standard}$mui_ups_charge: ($(date -d@$ups_runtime -u +%M:%S))\${goto 124}$(printf "%3d" $ups_charge)%\${goto 154}\${voffset 1}\${execbar 6 echo $ups_charge}"
  else
    echo -e "${font_standard}$mui_ups_charge:\${goto 124}$(printf "%3d" $ups_charge)%\${goto 154}\${voffset 1}\${execbar 6 echo $ups_charge}"
  fi
  echo -e "${font_standard}$mui_ups_load | $ups_power/$ups_power_nominal :\${goto 124}$(printf "%3d" $ups_load)%\${goto 154}\${voffset 1}\${execbar 6 echo $ups_load}"
  echo "\${font}\${voffset -4}"
fi


#### VM(s) Block

vm_running=`echo $user_pass | sudo -kS virsh list | grep running | awk '{print $2}'`
if [[ "$vm_running" != "" ]]; then
  time1=`date +%s`
  echo -e "\${font ${font_awesome_font}}$font_awesome_vpn\${font}\${goto 35} ${font_title}$mui_vm_title \${hr 2}"
  for vm_running_name in $vm_running ; do
    vm_core=`echo $user_pass | sudo -kS virsh dominfo $vm_running_name | grep "CPU(s)" | awk '{print $2}'`
    vm_ram=`echo $user_pass | sudo -kS virsh dominfo $vm_running_name | grep "Max memory" | cut -f 7 -d " "`
    vm_ram_gb=$(($vm_ram / 1048576 ))
    echo -e "${font_standard}$mui_vm_main $txt_align_right $vm_running_name / $vm_core Threads / $vm_ram_gb GiB"
  done
  time2=`date +%s`
  duration_block=$(($time2-$time1))
  if [[ "$debug" == "yes" ]]; then
    if [[ $duration_block -lt 60 ]]; then
      echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Ss)"
    else
      echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Mm:%Ss)"
    fi
  fi
  echo "\${font}\${voffset -4}"
fi



#### Services Block

if [[ "$services_list" != "" ]]; then
  time1=`date +%s`
  services_list_sorted=$(echo $services_list | xargs -n1 | sort -u | xargs)
  service_alert="0"
  for myservice in $services_list_sorted ; do
    service_mystate=`systemctl show -p SubState --value $myservice`
    if [[ "$service_mystate" == "running" ]]; then
      service_color=""
      if [[ -f ~/.conky/pushover/$myservice ]]; then
        rm ~/.conky/pushover/$myservice
        myservice_message=`echo -e "[ <b>${myservice^^}</b> ] $mui_pushover_service_restarted"`
        push-message "0" "Conky" "$myservice_message" "$push_token_app"
      fi
    else
      service_color="red"
      service_alert=$((service_alert+1))
      if [[ "$service_alert" == "1" ]]; then
        echo -e "\${font ${font_awesome_font}}$font_awesome_service\${font}\${goto 35} ${font_title}$mui_services_title \${hr 2}"
      fi
      echo -e "${font_standard}$myservice:${txt_align_right}\${color $service_color}\${execi 5 systemctl is-active $myservice}\$color"
      if [[ ! -f ~/.conky/pushover/$myservice ]]; then
        touch ~/.conky/pushover/$myservice
        if [[ "$user_pass" != "" ]]; then
          myservice_message=`echo -e "[ <b>${myservice^^}</b> ] $mui_pushover_service_restart"`
          echo $user_pass | sudo -kS service $myservice restart
        else
          myservice_message=`echo -e "[ <b>${myservice^^}</b> ] $mui_pushover_service"`
        fi
        push-message "0" "Conky" "$myservice_message" "$push_token_app"
      fi
    fi
  done
  if [[ "$service_alert" != "0" ]]; then
    time2=`date +%s`
    duration_block=$(($time2-$time1))
    if [[ "$debug" == "yes" ]]; then
      if [[ $duration_block -lt 60 ]]; then
        echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Ss)"
      else
        echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Mm:%Ss)"
      fi
    fi
    echo "\${font}\${voffset -4}"
  fi
  if [[ "$service_alert" == "0" ]] && [[ "$service_alert_view" == "yes" ]]; then
    echo -e "\${font ${font_awesome_font}}$font_awesome_service\${font}\${goto 35} ${font_title}$mui_services_title \${hr 2}"
    echo -e "${font_standard}$mui_services_ok"
    time2=`date +%s`
    duration_block=$(($time2-$time1))
    if [[ "$debug" == "yes" ]]; then
      if [[ $duration_block -lt 60 ]]; then
        echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Ss)"
      else
        echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Mm:%Ss)"
      fi
    fi
    echo "\${font}\${voffset -4}"
  fi
fi


#### CPU Block

time1=`date +%s`
echo -e "\${font ${font_awesome_font}}$font_awesome_cpu\${font}\${goto 35} ${font_title}$mui_cpu_title \${hr 2}"
echo -e "${font_standard}\${execi 1000 grep model /proc/cpuinfo | cut -d : -f2 | tail -1 | sed 's/\s//'}"
cpu_temp=`paste <(cat /sys/class/thermal/thermal_zone*/type 2>/dev/null) <(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null) | column -s $'\t' -t | sed 's/\(.\)..$/.\1°C/' | grep -e "x86_pkg_temp" -e "soc_dts0" | awk '{ print $NF }' | sed 's/\°C//' | sed 's/\..*//'`
if [[ "$cpu_temp" == "" ]]; then
  cpu_temp=`sensors | grep CPUTIN | awk '{print $2}' | sed 's/+//' | sed 's/\..*//'`
  if [[ "$cpu_temp" != "" ]]; then
    if [[ "$cpu_temp" -ge "85" ]]; then
      cpu_color="red"
    else
      cpu_color="lightgray"
    fi
## Issue with graphs
##    echo -e "${font_standard}\${color lightgray}\${cpugraph cpu}\$color"
    echo -e "${font_standard}$mui_cpu_cpu\${goto 130}\${cpu cpu}% \${goto 154}\${voffset 1}\${cpubar 6,140 cpu}${font_standard}\${goto 296}\${color $cpu_color}$bar\${color}\${font Noto Mono:regular:size=6}\${goto 299}\${voffset -1}\${color black}$cpu_temp°\$color"
  else
## Issue with graphs
##   echo -e "${font_standard}\${color lightgray}\${cpugraph cpu}\$color"
    echo -e "${font_standard}$mui_cpu_cpu\${goto 130}\${cpu cpu}% \${goto 154}\${voffset 1}\${cpubar 6 cpu}"
  fi
else
  cpu_num="1"
  for cpu_number in $cpu_temp ; do
    if [[ "$cpu_number" -ge "85" ]]; then
      cpu_color="red"
    else
      cpu_color="lightgray"
    fi
## Issue with graphs
##    echo -e "${font_standard}\${color lightgray}\${cpugraph cpu}\$color"
    echo -e "${font_standard}$mui_cpu_cpu\${goto 130}\${cpu cpu$cpu_num}% \${goto 154}\${voffset 1}\${cpubar 6,140 cpu$cpu_num}${font_standard}\${goto 296}\${color $cpu_color}$bar\${color}\${font Noto Mono:regular:size=6}\${goto 299}\${voffset -1}\${color black}${cpu_number:0:2}°\$color"
    cpu_num=$((cpu_num+1))
  done
fi
gpu_detect=`lspci | grep " VGA " | awk '{print $1}'`
for gpu_id in $gpu_detect ; do
  gpu_isolation=`lspci -nnv -s $gpu_id | grep vfio-pci`
  if [[ "$gpu_isolation" == "" ]]; then
    gpu_brand=`lspci -s $gpu_id | grep ' VGA '`
    if [[ "$gpu_brand" =~ "NVIDIA" ]]; then
      gpu_temp=`nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader`
      if [[ "$gpu_temp" -ge "85" ]]; then
        gpu_color="red"
      else
        gpu_color="lightgray"
      fi
    ##  echo -e "${font_standard}\${nvidia modelname}:\${goto 130}\${nvidia gpuutil}% \${goto 154}\${voffset 1}\${nvidiabar 6,140 gpuutil}${font_standard}\${goto 296}\${color $gpu_color}$bar\${color}\${font Noto Mono:regular:size=6}\${goto 299}\${voffset -1}\${color black}\${nvidia temp}°\$color"
    ## Wayland fix (nvidia plugin not working)
      gpu_usage=`nvidia-smi | grep % | cut -c 62-63`
      gpu_usage2=`echo $gpu_usage | sed "s/ //g"`
      gpu_usage3=`expr $gpu_usage`
      gpu_name=`nvidia-smi --query-gpu=gpu_name --format=csv | sed '$!d' | sed "s/NVIDIA //"`
      echo -e "${font_standard}$gpu_name:\${goto 130}$gpu_usage% \${goto 154}\${voffset 1}\${execbar 6,140 echo ${gpu_usage}}${font_standard}\${goto 296}\${color $gpu_color}$bar\${color}\${font Noto Mono:regular:size=6}\${goto 299}\${voffset -1}\${color black}$gpu_temp°\$color"
    fi
  fi
done
#if [[ "$gpu_brand" =~ "Intel" ]]; then
#  gpu_name=$(lspci | grep VGA | cut -d ':' -f3 | sed 's/^.//' | sed 's/ (.*//' | sed 's/Intel //' | sed 's/Corporation //')
#  echo -e "${font_standard}$gpu_name"
#fi
HandBrake_process=`ps aux | grep HandBrakeCLI | sed '/grep/d'`
if [[ "$HandBrake_process" != "" ]]; then
  if [[ -f "/opt/scripts/.convert2hdlight" ]]; then 
    HandBrake_line=`cat "/opt/scripts/.convert2hdlight" 2>/dev/null | sed -n '1p'`
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
    fi
    HandBrake_status=""
  elif [[ -f "$HOME/.config/plex_convert/conky-nas.handbrake" ]]; then
    source "$HOME/.config/plex_convert/conky-nas.handbrake"
    HandBrake_status=`echo " | $plex_convert_status"`
    HandBrake_file=$plex_convert_title
    HandBrake_categorie=$plex_convert_type
    HandBrake_progress_human=`echo $plex_convert_percent | sed "s/\..*//"`
    HandBrake_ETA=$plex_convert_time_left
  else
    HandBrake_progress_human=""
  fi
  if [[ "$HandBrake_progress_human" != "" ]]; then
    echo -e "${font_standard}$mui_cpu_handbrake$HandBrake_status:\${goto 124}$(printf "%3d" $HandBrake_progress_human)%\${goto 154}\${voffset 1}\${execbar 6 echo $HandBrake_progress_human}"
    echo -e "${font_standard}$mui_cpu_handbrake_ETA$txt_align_right$HandBrake_ETA"
    if [[ "$HandBrake_categorie" == "Film" ]] || [[ "$HandBrake_categorie" == "movie" ]]; then
      echo -e "${font_standard}$mui_cpu_handbrake_film$txt_align_right${HandBrake_file:0:40}"
    else
      echo -e "${font_standard}$mui_cpu_handbrake_serie$txt_align_right${HandBrake_file:0:40}"
    fi
  fi
fi
time2=`date +%s`
duration_block=$(($time2-$time1))
if [[ "$debug" == "yes" ]]; then
  if [[ $duration_block -lt 60 ]]; then
    echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Ss)"
  else
    echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Mm:%Ss)"
  fi
fi
echo "\${font}\${voffset -4}"


#### Memory Block

time1=`date +%s`
echo -e "\${font ${font_awesome_font}}$font_awesome_memory\${font}\${goto 35} ${font_title}$mui_memory_title \${hr 2}"
echo -e "${font_standard}$mui_memory_ram $txt_align_center \$mem / \$memmax $txt_align_right \$memperc%"
echo -e "${font_standard}\$membar"
echo -e "${font_standard}$mui_memory_swap $txt_align_center \${swap} / \${swapmax} $txt_align_right \${swapperc}%"
echo -e "${font_standard}\${swapbar}"
time2=`date +%s`
duration_block=$(($time2-$time1))
if [[ "$debug" == "yes" ]]; then
  if [[ $duration_block -lt 60 ]]; then
    echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Ss)"
  else
    echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Mm:%Ss)"
  fi
fi
echo "\${font}\${voffset -4}"


#### Scripts Block

if [[ "$scripts_list" != "" ]]; then
  scripts_view="0"
  scripts_list_sorted=$(echo $scripts_list | xargs -n1 | sort -u | xargs)
  for myscript in $scripts_list_sorted ; do
    myscript_process=`pgrep -x $myscript`
    myscript_human=`echo $myscript | sed 's/\.sh$//'`
    if [[ "$myscript_process" != "" ]]; then
      if [[ "$scripts_view" == "0" ]]; then echo -e "\${font ${font_awesome_font}}$font_awesome_scripts\${font}\${goto 35} ${font_title}$mui_scripts_title \${hr 2}"; fi
      myscript_process_time=`ps -o etime= -p $myscript_process | sed 's/ *//g' | sed 's/-/d /' | sed 's/\(.*\):/\1m /' | sed 's/\(.*\):/\1h /' | sed 's/^0//'`
      myscript_process_time+="s"
      myscript_process_time_human=`echo $myscript_process_time`
      myscript_process_time_check=`echo "$myscript_process_time" | grep "^0m"`
      if [[ "$myscript_process_time_check" != "" ]]; then
        myscript_process_time_human=`echo "$myscript_process_time" | sed 's/0m //'`
      fi
      myscript_process_time_check=`echo "$myscript_process_time" | grep "h"`
      if [[ "$myscript_process_time_check" != "" ]]; then
        myscript_process_time_human=`echo "$myscript_process_time" | sed 's/m.*/m/'`
      fi
      myscript_process_time_check=`echo "$myscript_process_time" | grep "d"`
      if [[ "$myscript_process_time_check" != "" ]]; then
        myscript_process_time_human=`echo "$myscript_process_time" | sed 's/h.*/h/'`
      fi
      echo -e "${font_standard}$myscript_human: $txt_align_center$txt_align_right$myscript_process_time_human $myscript_process $font_awesome_scripts_ok"
      scripts_view=$((scripts_view+1))
    else
      if [[ "$user_pass" != "" ]]; then
        myscript_lock=`echo $user_pass | sudo -kS ls /root/.config/$myscript_human/lock-$myscript_human &>/dev/null`
        if [[ "$myscript_lock" != "" ]]; then
          if [[ "$scripts_remove_lock" == "yes" ]]; then
            echo $user_pass | sudo -kS rm /root/.config/$myscript_human/lock-$myscript_human &>/dev/null
          fi
          if [[ "$scripts_view" == "0" ]]; then echo -e "\${font ${font_awesome_font}}$font_awesome_scripts\${font}\${goto 35} ${font_title}$mui_scripts_title \${hr 2}"; fi
          echo -e "${font_standard}$myscript_human:$txt_align_right\${offset -2}LOCK $font_awesome_scripts_ko"
          scripts_view=$((scripts_view+1))
        else
          if [[ "$scripts_view_ko" == "yes" ]]; then
            if [[ "$scripts_view" == "0" ]]; then echo -e "\${font ${font_awesome_font}}$font_awesome_scripts\${font}\${goto 35} ${font_title}$mui_scripts_title \${hr 2}"; fi
            echo -e "${font_standard}$myscript_human:$txt_align_right\${offset -2}$font_awesome_scripts_ko"
            scripts_view=$((scripts_view+1))
          fi
        fi
      else
        if [[ "$scripts_view_ko" == "yes" ]]; then
          if [[ "$scripts_view" == "0" ]]; then echo -e "\${font ${font_awesome_font}}$font_awesome_scripts\${font}\${goto 35} ${font_title}$mui_scripts_title \${hr 2}"; fi
          echo -e "${font_standard}$myscript_human:$txt_align_right\${offset -2}$font_awesome_scripts_ko"
          scripts_view=$((scripts_view+1))
        fi
      fi
    fi
  done
  if [[ "$scripts_view" != "0" ]]; then
    echo "\${font}\${voffset -4}"
  fi
fi


#### DiskUsage Block

time1=`date +%s`
echo -e "\${font ${font_awesome_font}}$font_awesome_diskusage\${font}\${goto 35} ${font_title}$mui_diskusage_title \${hr 2}"
drives=`ls /dev/nvme1n[1-9]p[1-9] /dev/nvme0n[1-9]p[1-9] /dev/mmcblk[1-9]p[1-9] /dev/sd*[1-9] 2>/dev/null`
for drive in $drives ; do
  mount_point=`grep "^$drive " /proc/mounts | grep -v "/snap/" | cut -d ' ' -f 2`
  if [[ "$mount_point" != "" ]]; then
    disk_free=`df $drive | sed 1d | awk '{print $4}'`
    disk_free_human=`echo $disk_free | numfmt --from-unit=1024 --to=si`
    disk_used=`df $drive | sed 1d | awk '{print $3}'`
    disk_used_human=`echo $disk_used | numfmt --from-unit=1024 --to=si`
    disk_total=`df $drive | sed 1d | awk '{print $2}'`
    disk_total_human=`echo $disk_total | numfmt --from-unit=1024 --to=si`
    disk_usage=`df $drive | sed 1d | awk '{print $5}' | sed 's/%//'`
    if [[ "$user_pass" != "" ]]; then
      disk_interface=`udevadm info --query=all --name=$drive | grep ID_BUS`
      disk_support=`udevadm info --query=all --name=$drive | grep ID_DRIVE_FLASH_SD`
      if [[ "$disk_interface" =~ "usb" ]] || [[ "$disk_interface" =~ "scsi" ]] || [[ "$disk_support" != "" ]]; then
        disk_temp=""
        disk_color="lightblue"
      else
        disk_temp=`echo $user_pass | sudo -kS hddtemp $drive 2>/dev/null | awk '{ print $NF }' | sed 's/°C//'`
        if [[ "$drive" =~ "nvme" ]]; then
          disk_temp=`echo $user_pass | sudo -kS nvme smart-log $drive 2>/dev/null | grep "temperature" | awk '{ print $3 }'`
        fi
        if [[ "$disk_temp" -ge "45" ]]; then
          if [[ "$drive" =~ "nvme" ]]; then
            if [[ "$disk_temp" -ge "70" ]]; then
              disk_color="red"
            else
              disk_color="lightgray"
            fi
          else 
            disk_color="red"
          fi
        else
          disk_color="lightgray"
        fi
        drive_short=`basename $drive`
        if [[ "$drive" =~ "nvme" ]]; then
          drive_smart=`echo $drive`
        else
          drive_smart=`echo $drive | sed 's/[1-9]//'`
        fi       
        if [[ ! -d ~/.conky/SMART ]]; then
          mkdir ~/.conky/SMART
        fi
        printf "\${execi 3600 echo $user_pass | sudo -kS smartctl -a $drive_smart > ~/.conky/SMART/$drive_short.log }"
        ## SMART STATISTICS
        ## smartctl -l devstat /dev/sdd | grep -i uncorrectable | awk '{ print $4 }'
        smart_enabled=`cat ~/.conky/SMART/$drive_short.log | grep "SMART support is:" | awk '{print $NF}' | tail -1`
        smart_status=`cat ~/.conky/SMART/$drive_short.log | grep "SMART overall-health" | awk '{print $NF}'`
        if [[ "$drive" =~ "nvme" ]]; then
          if [[ "$smart_status" == "PASSED" ]]; then
            smart_enabled="Enabled"
          fi
        fi
        smart_offline_uncorrectable=`cat ~/.conky/SMART/$drive_short.log | grep -i "Offline_Uncorrectable" | awk '{print $NF}'`
        if [[ "$drive" =~ "nvme" ]]; then
          smart_offline_uncorrectable=`cat ~/.conky/SMART/$drive_short.log | grep -i "Media and Data Integrity Errors:" | awk '{print $NF}'`
        fi
        if [[ "$smart_offline_uncorrectable" == "" ]]; then
          smart_offline_uncorrectable=`cat ~/.conky/SMART/$drive_short.log | grep -i "Reallocated_Sector_Ct" | awk '{print $NF}'`
        fi
        if [[ "$smart_enabled" == "Enabled" ]]; then
          if [[ "$smart_status" == "PASSED" ]]; then
            if [[ "$smart_offline_uncorrectable" == "0" ]]; then
              smart_glyph="\uf0c8"
              smart_color="lightgreen"
            else
              smart_glyph="\uf0c8"
              smart_color="orange"
              last_smart_error=`cat ~/.conky/SMART/$drive_short.error 2>/dev/null`
              if [[ "$smart_offline_uncorrectable" != "$last_smart_error" ]]; then
                smart_serial=`cat ~/.conky/SMART/$drive_short.log | grep "Serial Number:" | awk '{print $NF}' | tail -1`
                smart_size=`df -Hl $drive | awk '{ print $2 }' | tail -1`
                smart_age=`cat ~/.conky/SMART/$drive_short.log | grep -i "Power_On_Hours" | awk '{print $NF}' | tail -1 | awk '{print $1/24}'`
                push_content=`echo -e "[ <b>SMART</b> ] $mui_smart_error_title\n\n<b>$mui_smart_error_main</b> $drive\n<b>$mui_smart_error_serial</b> $smart_serial\n<b>$mui_smart_error_size</b> $smart_size\n<b>$mui_smart_error_age</b> $smart_age\n<b>$mui_smart_error_errors</b> $smart_offline_uncorrectable"`
                push-message "0" "Conky" "$push_content" "$push_token_app"
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
      fi
      if [[ ! -d ~/.conky/Temp ]]; then
          mkdir ~/.conky/Temp
      fi
      touch ~/.conky/Temp/drives.log
      touch ~/.conky/Temp/usb.log
      if [[ "$disk_temp" != "" ]]; then
        if [[ ! "$mount_point" =~ "boot" ]]; then
##          echo -e "\${voffset -1}\${offset -5}\${voffset 3}\${font FontAwesome:regular:size=5}\${color $smart_color}$smart_glyph\${color}\${voffset -3}\${goto 6}${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,88 echo $disk_usage}${font_standard}\${color $disk_color}\${goto 296}$bar\${color}\${font Noto Mono:regular:size=6}\${goto 299}\${voffset -1}\${color black}${disk_temp:0:2}°\$color"
          echo -e "\${voffset -1}\${offset -5}\${voffset 3}\${font FontAwesome:regular:size=5}\${color $smart_color}$smart_glyph\${color}\${voffset -3}\${goto 6}${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,88 echo $disk_usage}${font_standard}\${color $disk_color}\${goto 296}$bar\${color}\${font Noto Mono:regular:size=6}\${goto 299}\${voffset -1}\${color black}${disk_temp:0:2}°\$color" >> ~/.conky/Temp/drives.log
        fi
##        echo -e "\${voffset -1}\${offset -5}\${voffset 3}\${font FontAwesome:regular:size=5}\${color $smart_color}$smart_glyph\${color}\${voffset -3}\${goto 6}${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,88 echo $disk_usage}${font_standard}\${color $disk_color}\${goto 296}$bar\${color}\${font Noto Mono:regular:size=6}\${goto 299}\${voffset -1}\${color black}${disk_temp:0:2}°\$color"
      else
        if [[ "$disk_interface" =~ "usb" ]] || [[ "$disk_support" != "" ]]; then
          echo -e "\${voffset 1}${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,88 echo $disk_usage}${font_standard}\${color $disk_color}\${goto 296}$bar\${color}\${font Noto Mono:regular:size=6}\${goto 298}\${voffset -1}\${color black}\$color" >> ~/.conky/Temp/usb.log
        else
        test=1
          if [[ ! "$mount_point" =~ "boot" ]]; then
##            echo -e "\${voffset -1}\${offset -5}\${voffset 3}\${font FontAwesome:regular:size=5}\${color $smart_color}$smart_glyph\${color}\${voffset -3}\${goto 6}${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,88 echo $disk_usage}${font_standard}\${color $disk_color}\${goto 296}$bar\${color}\${font Noto Mono:regular:size=6}\${goto 298}\${voffset -1}\${color black}\$color"
            echo -e "\${voffset -1}\${offset -5}\${voffset 3}\${font FontAwesome:regular:size=5}\${color $smart_color}$smart_glyph\${color}\${voffset -3}\${goto 6}${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,88 echo $disk_usage}${font_standard}\${color $disk_color}\${goto 296}$bar\${color}\${font Noto Mono:regular:size=6}\${goto 298}\${voffset -1}\${color black}\$color" >> ~/.conky/Temp/drives.log
          fi
##          echo -e "\${voffset -1}\${offset -5}\${voffset 3}\${font FontAwesome:regular:size=5}\${color $smart_color}$smart_glyph\${color}\${voffset -3}\${goto 6}${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,88 echo $disk_usage}${font_standard}\${color $disk_color}\${goto 296}$bar\${color}\${font Noto Mono:regular:size=6}\${goto 298}\${voffset -1}\${color black}\$color"
        fi
      fi
    else
      disk_interface=`udevadm info --query=all --name=$drive | grep ID_BUS`
      disk_support=`udevadm info --query=all --name=$drive | grep ID_DRIVE_FLASH_SD`
      if [[ "$disk_interface" =~ "usb" ]] || [[ "$disk_support" != "" ]]; then
        disk_color="lightblue"
      else
        disk_color="lightgray"
      fi
      if [[ ! "$mount_point" =~ "boot" ]]; then
        echo -e "${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,110 echo $disk_usage}"
      fi
##      echo -e "${font_standard}${mount_point:0:18}${txt_align_right}\${goto 128}[$(printf "%04s" $disk_free_human) / $(printf "%03d" $disk_usage)%]\${voffset 1}\${execbar 6,110 echo $disk_usage}"
    fi
  fi
done
cat ~/.conky/Temp/drives.log | grep "/media" > ~/.conky/Temp/media.log
cat ~/.conky/Temp/drives.log | grep "orange" > ~/.conky/Temp/alert.log
cat ~/.conky/Temp/drives.log | grep "red" >> ~/.conky/Temp/alert.log
sed -i '/orange/d' ~/.conky/Temp/drives.log
sed -i '/red/d' ~/.conky/Temp/drives.log
sed -i '/\/media\//d' ~/.conky/Temp/drives.log
sed -i '/\/snap\//d' ~/.conky/Temp/drives.log
sort ~/.conky/Temp/drives.log
cat ~/.conky/Temp/media.log
cat ~/.conky/Temp/usb.log
rm ~/.conky/Temp/drives.log
rm ~/.conky/Temp/usb.log
rm ~/.conky/Temp/media.log
if [ -s ~/.conky/Temp/alert.log ]; then
  echo ""
  ##echo "Alert"
  cat ~/.conky/Temp/alert.log
  rm ~/.conky/Temp/alert.log
fi
time2=`date +%s`
duration_block=$(($time2-$time1))
if [[ "$debug" == "yes" ]]; then
  if [[ $duration_block -lt 60 ]]; then
    echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Ss)"
  else
    echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Mm:%Ss)"
  fi
fi
echo "\${font}\${voffset -4}"

#### Network Block

time1=`date +%s`
if [[ "$net_adapter" != "" ]]; then
  vpn_detected=`ifconfig | grep "tun[0-9]"`
  if [[ "$vpn_detected" != "" ]]; then
    echo -e "\${font ${font_awesome_font}}$font_awesome_network_secured\${font}\${goto 35} ${font_title}$mui_network_title_secured \${hr 2}"
  else
    echo -e "\${font ${font_awesome_font}}$font_awesome_network\${font}\${goto 35} ${font_title}$mui_network_title \${hr 2}"
  fi
  net_adapter_number=`echo $net_adapter | wc -w`
  if [[ "$net_adapter_number" == "1" ]]; then
    if [[ "$net_adapter" =~ "wl" ]]; then
      echo -e "${font_standard}$mui_network_adapter $txt_align_right $net_adapter ($font_awesome_network_wifi \${wireless_essid $net_adapter})"
    else
      net_adapter_speed=`cat /sys/class/net/$net_adapter/speed`
      echo -e "${font_standard}$mui_network_adapter $txt_align_right $net_adapter ($net_adapter_speed Mbps)"
    fi
  fi
  net_ip_public=`dig -4 +short myip.opendns.com @resolver1.opendns.com`
  if [[ "$vpn_detected" != "" ]]; then
#    echo -e "${font_standard}$mui_network_vpn $txt_align_right\${execi 5 systemctl is-active $vpn_service}"
##    echo -e "${font_standard}$mui_network_ip_public $txt_align_right$net_ip_public"
    if [[ "$net_adapter_number" == "1" ]]; then
      net_ip_box=`dig -b $(hostname -I | cut -d' ' -f1) +short myip.opendns.com @resolver1.opendns.com`
      if [[ "$net_ip_box" =~ "$net_ip_public" ]] && id -u "vpn" >/dev/null 2>&1; then
        net_ip_public=`echo $user_pass | sudo -kSu vpn -i -- wget -q -O - ipinfo.io/ip`
        echo -e "${font_standard}$mui_network_ip_tunnel $txt_align_right$net_ip_public"
      else
        echo -e "${font_standard}$mui_network_ip_public $txt_align_right$net_ip_public"
      fi
      echo -e "${font_standard}$mui_network_ip_box $txt_align_right$net_ip_box"
      if [[ "$net_ip_box" == "$net_ip_public" ]]; then
        if [[ ! -f ~/.conky/pushover/vpn_error ]]; then
          touch ~/.conky/pushover/vpn_error
          if [[ "$user_pass" != "" ]]; then
            mynetwork_message=`echo -e "[ <b>VPN</b> ] $mui_network_vpn_restart"`
            echo $user_pass | sudo -kS service $vpn_service restart &>/dev/null
          else
            mynetwork_message=`echo -e "[ <b>VPN</b> ] $mui_network_vpn_ko"`
          fi
          push-message "0" "Conky" "$mynetwork_message" "$push_token_app"
        fi
      else
        if [[ -f ~/.conky/pushover/vpn_error ]]; then
          rm ~/.conky/pushover/vpn_error
        fi
      fi
    fi
  else
    echo -e "${font_standard}$mui_network_ip_public $txt_align_right$net_ip_public"
  fi
  if [[ "$net_adapter_number" != "1" ]]; then
    net_adapter_default=`route -n | grep '^0.0.0.0' | sed '/tun0/d' | sed -n '1p' | awk '{print $NF}'`
    for net_adapter_device in $net_adapter ; do
      if [[ "$net_adapter_device" =~ "wl" ]]; then
        echo -e "${font_standard}$mui_network_adapter $txt_align_right $net_adapter_device ($font_awesome_network_wifi \${wireless_essid $net_adapter_device})"
      else
        net_adapter_speed=`cat /sys/class/net/$net_adapter_device/speed`
        echo -e "${font_standard}$mui_network_adapter $txt_align_right $net_adapter_device ($net_adapter_speed Mbps)"
      fi
      if [[ "$vpn_detected" != "" ]]; then
        if [[ "$net_adapter_device"  == "$net_adapter_default" ]]; then
          net_adapter_device_ip=`ip address show $net_adapter_device | grep 'inet' | sed '/inet6/d' | awk '{print $2}' | sed 's/\/.*//'`
          net_adapter_device_ip_box=`dig -b $net_adapter_device_ip +short myip.opendns.com @resolver1.opendns.com`
          if [[ "$net_adapter_device_ip" =~ "$net_adapter_device_ip_box" ]] && id -u "vpn" >/dev/null 2>&1; then
            net_adapter_device_ip=`echo $user_pass | sudo -kS -u vpn -i -- ip address show $net_adapter_device | grep 'inet' | sed '/inet6/d' | awk '{print $2}' | sed 's/\/.*//'`
            vpn_title="Tunnel IP:"
          else
            vpn_title="Current IP:"
          fi
          echo -e "${font_standard}$mui_network_ip_box $txt_align_right$net_adapter_device_ip_box"
          if [[ "$net_adapter_device_ip_box" == "$net_ip_public" ]]; then
            if [[ ! -f ~/.conky/pushover/vpn_error ]]; then
              touch ~/.conky/pushover/vpn_error
              if [[ "$user_pass" != "" ]]; then
                mynetwork_message=`echo -e "[ <b>VPN</b> ] $mui_network_vpn_restart"`
                echo $user_pass | sudo -kS service $vpn_service restart &>/dev/null
              else
                mynetwork_message=`echo -e "[ <b>VPN</b> ] $mui_network_vpn_ko"`
              fi
              push-message "0" "Conky" "$mynetwork_message" "$push_token_app"
            fi
          else
            if [[ -f ~/.conky/pushover/vpn_error ]]; then
              rm ~/.conky/pushover/vpn_error
            fi
          fi
        fi
      fi
      echo -e "${font_standard}$mui_network_down \${downspeed $net_adapter_device}  ${txt_align_right}$mui_network_up \${upspeed $net_adapter_device}"
## Issue with graphs            
##      echo -e "\${color lightgray}\${downspeedgraph $net_adapter_device 25,150 } ${txt_align_right}\${upspeedgraph $net_adapter_device 25,150 }\$color"
    done
  else
    echo -e "${font_standard}$mui_network_down \${downspeed $net_adapter}  ${txt_align_right}$mui_network_up \${upspeed $net_adapter}"
## Issue with graphs
##    echo -e "\${color lightgray}\${downspeedgraph $net_adapter 25,150 } ${txt_align_right}\${upspeedgraph $net_adapter 25,150 }\$color"
  fi
else
  echo -e "\${font ${font_awesome_font}}$font_awesome_network\${font}\${goto 35} ${font_title}$mui_network_title \${hr 2}"
  echo ""
  echo -e "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_network_error\$color"
fi
time2=`date +%s`
duration_block=$(($time2-$time1))
if [[ "$debug" == "yes" ]]; then
  if [[ $duration_block -lt 60 ]]; then
    echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Ss)"
  else
    echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Mm:%Ss)"
  fi
fi
echo "\${font}\${voffset -4}"


#### Connexion Block

if [[ "$net_adapter" != "" ]]; then
  time1=`date +%s`
  connexion_ssh_list=`w | sed '1,2d' | sed '/session/d' | sed '/ - /d' | sed '/tmux/d' | tr -s ' ' | cut -d ' ' -f 1,3 | sed 's/^\(.*'$look'.*\)$/SSH: \1/'`
  if [[ "$connexion_ssh_list" != "" ]]; then
    echo -e "\${font ${font_awesome_font}}$font_awesome_connexion\${font}\${goto 35} ${font_title}$mui_connexion_title \${hr 2}"
    echo -e "${font_standard}$connexion_ssh_list"
  fi
  if [[ "$user_pass" != "" ]]; then
    connexion_vino_list=`echo $user_pass | sudo -kS netstat -natp 2>/dev/null | grep ESTABLISHED | grep 'vino-server' | tr -s ' ' | cut -d ' ' -f 5 | sed 's/:.*//g' | sed 's/^\(.*\)/VNC: \1/'`
    if [[ "$connexion_vino_list" != "" ]]; then
      if [[ "$connexion_ssh_list" = "" ]]; then echo -e "\${font ${font_awesome_font}}$font_awesome_connexion\${font}\${goto 35} ${font_title}$mui_connexion_title \${hr 2}"; fi
      echo -e "${font_standard}$connexion_vino_list"
    fi
  fi
  if [[ "$connexion_ssh_list" != "" ]] || [[ "$connexion_vino_list" != "" ]]; then
    time2=`date +%s`
    duration_block=$(($time2-$time1))
    if [[ "$debug" == "yes" ]]; then
      if [[ $duration_block -lt 60 ]]; then
        echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Ss)"
      else
        echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Mm:%Ss)"
      fi
    fi
    echo "\${font}\${voffset -4}"
  fi
fi


#### Transmission Block

if [[ "$net_adapter" != "" ]]; then
  if [[ "$transmission_check" == "yes" ]]; then
    time1=`date +%s`
    transmission_state=`systemctl show -p SubState --value transmission-daemon`
    if [[ "$transmission_state" != "dead" ]]; then
      echo -e "\${font ${font_awesome_font}}$font_awesome_transmission\${font}\${goto 35} ${font_title}$mui_transmission_title \${hr 2}"
#      echo -e "${font_standard}$mui_transmission_state ${txt_align_right}\${execi 5 systemctl is-active transmission-daemon}"
      if [[ "$transmission_ip" != "" ]] && [[ "$transmission_port" != "" ]] && [[ "$transmission_login" != "" ]] && [[ "$transmission_password" != "" ]]; then
        test_transmission=`transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l 2>/dev/null`
        if [[ "$test_transmission" != "" ]]; then
          transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l >~/.conky/transm.log
          transmission_queue=`cat ~/.conky/transm.log | sed '/^ID/d' | sed '/^Sum:/d' | sed '/ Done /d' | wc -l`
          echo "${font_standard}$mui_transmission_queue ${txt_align_right} $transmission_queue"
          transmission_down=`cat ~/.conky/transm.log | grep Sum: | awk '{ print $NF }' | sed "s/\..*//"`
          transmission_down_human=`numfmt --to=iec-i --from-unit=1024 --suffix=B $transmission_down`
          transmission_up=`cat ~/.conky/transm.log | grep Sum: | awk '{ print $(NF-1) }' | sed "s/\..*//"`
          transmission_up_human=`numfmt --to=iec-i --from-unit=1024 --suffix=B $transmission_up`
          echo -e "${font_standard}$mui_transmission_down $transmission_down_human ${txt_align_right}$mui_transmission_up $transmission_up_human"
          rm ~/.conky/transm.log
        else
          echo ""
          echo -e "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_transmission_error\$color"
        fi
      else
        ## was set to settings2 instead of settings to disable
        if [[ -f "/etc/transmission-deamon/settings2.json" ]]; then
          transmission_port=`echo $user_pass | sudo -kS cat /etc/transmission-daemon/settings.json &>/dev/null | jq -r '."rpc-port"'`
          transmission_ip="localhost"
          echo $user_pass | sudo -kS cat /etc/transmission-daemon/settings.json &>/dev/null | jq -r '."rpc-username"' | sed 's/./\\&/g' >temp_tr.log
          transmission_login=`cat temp_tr.log`
          rm temp_tr.log
          echo $user_pass | sudo -kS cat /etc/transmission-daemon/settings.json &>/dev/null | jq -r '."rpc-password"' | sed 's/./\\&/g' >temp_tr.log
          transmission_password=`cat temp_tr.log`
          rm temp_tr.log
          echo -e "${font_standard}$mui_transmission_queue ${txt_align_right}\${exec transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l 2>/dev/null | sed '/^ID/d' | sed '/^Sum:/d' | sed '/ Done /d' | wc -l}"
          transmission_down=`transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l 2>/dev/null | grep Sum: | awk '{ print $5 }' | sed "s/\..*//"`
          transmission_down_human=`numfmt --to=iec-i --from-unit=1024 --suffix=B $transmission_down`
          transmission_up=`transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l 2>/dev/null | grep Sum: | awk '{ print $4 }' | sed "s/\..*//"`
          transmission_up_human=`numfmt --to=iec-i --from-unit=1024 --suffix=B $transmission_up`
          echo "${font_standard}$mui_transmission_down $transmission_down_human ${txt_align_right}$mui_transmission_up $transmission_up_human"
        else
          echo ""
          echo -e "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_transmission_error\$color"
        fi
      fi
    else
      if [[ "$transmission_ip" != "" ]] && [[ "$transmission_port" != "" ]] && [[ "$transmission_login" != "" ]] && [[ "$transmission_password" != "" ]]; then
        echo -e "\${font ${font_awesome_font}}$font_awesome_transmission\${font} ${font_title}$mui_transmission_title \${hr 2}"
        test_transmission=`transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l 2>/dev/null`
        if [[ "$test_transmission" != "" ]]; then
          transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l >transm.log
          transmission_queue=`cat transm.log | sed '/^ID/d' | sed '/^Sum:/d' | sed '/ Done /d' | wc -l`
          echo -e "${font_standard}$mui_transmission_queue ${txt_align_right}$transmission_queue "
          transmission_down=`cat transm.log | grep Sum: | awk '{ print $NF }' | sed "s/\..*//"`
          transmission_down_human=`numfmt --to=iec-i --from-unit=1024 --suffix=B $transmission_down`
          transmission_up=`cat transm.log | grep Sum: | awk '{ print $(NF-1) }' | sed "s/\..*//"`
          transmission_up_human=`numfmt --to=iec-i --from-unit=1024 --suffix=B $transmission_up`
          echo -e "${font_standard}$mui_transmission_down $transmission_down_human ${txt_align_right}$mui_transmission_up $transmission_up_human"
          rm transm.log
        else
          echo ""
          echo -e "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_transmission_error\$color"
        fi
      fi
    fi
    if [[ "$transmission_push_finished" == "yes" ]] && [[ "$transmission_push_activated" == "yes" ]]; then
      if [[ ! -d ~/.conky/pushover/TRANSMISSION ]]; then mkdir -p ~/.conky/pushover/TRANSMISSION; fi
      transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l | sed '/^ID/d' | sed '/^Sum:/d' > ~/.conky/transmission_list.log
      check_finished=`cat ~/.conky/transmission_list.log | grep "Finished" | awk '{print $1}'`
      finished_list=($check_finished)
      for i in "${finished_list[@]}"; do
        item_finished=`echo $i | sed -r 's/\*//g'`
        if [[ ! -f ~/.conky/pushover/TRANSMISSION/$item_finished ]]; then
          torrent_name=`cat ~/.conky/transmission_list.log | grep "^[[:space:]]*$item_finished" | grep "[[:space:]]Finished[[:space:]]" | sed -n '1p' | sed "s/.*[[:space:]]Finished[[:space:]]//" | sed 's/^[[:space:]]*//'`
          myfinished_message=`echo -e "[ <b>TRANSMISSION</b> ] <b>$torrent_name</b>: $mui_transmission_finished"`
          push-message "0" "Conky" "$myfinished_message" "$transmission_push_token"
          touch ~/.conky/pushover/TRANSMISSION/$item_finished
        fi
      done
      rm ~/.conky/transmission_list.log
    fi
    if [[ ! -f ~/.conky/transmission-done ]] && [[( "$transmission_autoclean" == "yes" ) || ( "$transmission_clean_unregistered" == "yes" ) || ( "$transmission_clean_finished" == "yes" )]]; then
      transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -l | sed '/^ID/d' | sed '/^Sum:/d' > ~/.conky/transmission_list.log
      if [[ "$transmission_autoclean" == "yes" ]] || [[ "$transmission_clean_unregistered" == "yes" ]]; then
        check_unregistered=`cat ~/.conky/transmission_list.log | grep "*" | awk '{print $1}'`
        unregistered_list=($check_unregistered)
        for h in "${unregistered_list[@]}"; do
          item_unregistered=`echo $h | sed -r 's/\*//g'`
          transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -t $item_unregistered --remove-and-delete >/dev/null
          if [[ "$transmission_push_activated" == "yes" ]]; then
            if [[ -f ~/.conky/pushover/TRANSMISSION/$item_unregistered ]]; then rm ~/.conky/pushover/TRANSMISSION/$item_unregistered; fi
            torrent_name=`cat ~/.conky/transmission_list.log | grep "^[[:space:]]*$h" | sed -e "s/.*[[:space:]]Finished[[:space:]]//" -e "s/.*[[:space:]]Downloading[[:space:]]//" -e "s/.*[[:space:]]Queued[[:space:]]//" -e "s/[[:space:]]Stopped[[:space:]]//" | sed "s/^[[:space:]]*//"`
            myunregistered_message=`echo -e "[ <b>TRANSMISSION</b> ] <b>$torrent_name</b> $mui_transmission_deleted"`
            push-message "0" "Conky" "$myunregistered_message" "$transmission_push_token"
          fi
        done
      fi
      if [[ "$transmission_autoclean" == "yes" ]] || [[ "$transmission_clean_finished" == "yes" ]]; then
        check_finished=`cat ~/.conky/transmission_list.log | grep "Finished" | awk '{print $1}'`
        finished_list=($check_finished)
        for i in "${finished_list[@]}"; do
          item_finished=`echo $i | sed -r 's/\*//g'`
          transmission-remote $transmission_ip:$transmission_port -n $transmission_login:$transmission_password -t $item_finished -r >/dev/null
          if [[ "$transmission_push_activated" == "yes" ]]; then
            if [[ -f ~/.conky/pushover/TRANSMISSION/$item_finished ]]; then rm ~/.conky/pushover/TRANSMISSION/$item_finished; fi
            torrent_name=`cat ~/.conky/transmission_list.log | grep "^[[:space:]]*$item_finished" | grep "[[:space:]]Finished[[:space:]]" | sed -n '1p' | sed "s/.*[[:space:]]Finished[[:space:]]//" | sed 's/^[[:space:]]*//'`
            myfinished_message=`echo -e "[ <b>TRANSMISSION</b> ] <b>$torrent_name</b> $mui_transmission_deleted"`
            push-message "0" "Conky" "$myfinished_message" "$transmission_push_token"
          fi
        done
      fi
      rm ~/.conky/transmission_list.log
      touch ~/.conky/transmission-done
    fi
    time2=`date +%s`
    duration_block=$(($time2-$time1))
    if [[ "$debug" == "yes" ]]; then
      if [[ $duration_block -lt 60 ]]; then
        echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Ss)"
      else
        echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Mm:%Ss)"
      fi
    fi
    echo "\${font}\${voffset -4}"
  fi
fi


#### Plex Block

if [[ "$net_adapter" != "" ]]; then
  if [[ "$plex_check" == "yes" ]]; then
    time1=`date +%s`
    plex_state=`systemctl show -p SubState --value plexmediaserver`
    if [[ "$plex_state" != "dead" ]] || [[( "$plex_ip" != "" ) && ( "$plex_port" != "" ) && ( "$plex_token" != "" )]]; then
      echo -e "\${font ${font_awesome_font}}$font_awesome_plex\${font}\${goto 35} ${font_title}$mui_plex_title \${hr 2}"
#      if [[ "$plex_state" != "dead" ]]; then
#        echo -e "${font_standard}$mui_plex_state ${txt_align_right}\${execi 5 systemctl is-active plexmediaserver}"
#      fi
      if [[ "$plex_token" == "" ]]; then
        if [[ "$user_pass" != "" ]]; then
          echo $user_pass | sudo -kS updatedb &>/dev/null
          plex_token=`cat "$(locate Preferences.xml | grep "plexmediaserver" | sed -n '1p')" | sed -n 's/.*PlexOnlineToken="\([[:alnum:]_-]*\).*".*/\1/p'`
          plex_token_line=$(sed -n '/^plex_token=/=' ~/.conky/conky-nas.conf)
          if [[ "$plex_token_line" != "" ]]; then
            sed -i 's|plex_token=.*|plex_token="'$plex_token'"|' ~/.conky/conky-nas.conf
          else
            echo -e "\nplex_token=$plex_token" >> ~/.conky/conky-nas.conf
          fi
        fi
      fi
      if [[ "$plex_ip" == "" ]]; then
        plex_ip="localhost"
        plex_ip_line=$(sed -n '/^plex_ip=/=' ~/.conky/conky-nas.conf)
        if [[ "$plex_ip_line" != "" ]]; then
          sed -i 's|plex_ip=.*|plex_ip="'$plex_ip'"|' ~/.conky/conky-nas.conf
        else
          echo -e "\nplex_ip=$plex_ip" >> ~/.conky/conky-nas.conf
        fi
      fi
      if [[ "$plex_port" == "" ]]; then
        plex_port="32400"
        plex_port_line=$(sed -n '/^plex_port=/=' ~/.conky/conky-nas.conf)
        if [[ "$plex_port_line" != "" ]]; then
          sed -i 's|plex_port=.*|plex_port="'$plex_port'"|' ~/.conky/conky-nas.conf
        else
          echo -e "\nplex_port=$plex_port" >> ~/.conky/conky-nas.conf
        fi
      fi
      ## Plex.tv IP used
      if [[ "$plex_extras" == "yes" ]]; then
        plexip_used=`curl --silent https://plex.tv/pms/:/ip`
        echo $font_standard"$mui_plexip_used"$txt_align_right$plexip_used""
        ## end but if plexip_used == vpn then notifcould be great
        plex_pid=`service plexmediaserver status | grep "Main PID" | awk '{print $3}'`
        plex_prlimit=`echo $user_pass | sudo -kS prlimit --pid $plex_pid --as --output HARD | tail -n 1`
        plex_ram_used=`echo $user_pass | sudo -kS ps_mem -p $plex_pid -t | numfmt --to=iec`
        re='^[0-9]+$'
        if [[ "$plex_prlimit" =~ $re ]]; then
          plex_prlimit=`echo $plex_prlimit | numfmt --to=iec`
        else
          plex_prlimit="$mui_plex_none"
        fi
        #echo $font_standard"$mui_plex_pid"$txt_align_right$plex_pid" "
        #echo $font_standard"$mui_plex_prlimit"$txt_align_right$plex_prlimit" "
        if [[ "$plex_ram_used" != "" ]]; then
          echo $font_standard"$mui_plex_pid $plex_pid ($plex_ram_used)"$txt_align_right"$mui_plex_prlimit $plex_prlimit"
        else
          echo $font_standard"$mui_plex_pid $plex_pid"$txt_align_right"$mui_plex_prlimit $plex_prlimit"
        fi
      fi
      if [[ ! -d ~/.conky/Temp ]]; then
        mkdir ~/.conky/Temp
      fi
      touch ~/.conky/Temp/plex_transcode.log
      touch ~/.conky/Temp/plex_direct.log
      touch ~/.conky/Temp/plex_music.log
      plex_xml=`curl --silent http://$plex_ip:$plex_port/status/sessions?X-Plex-Token=$plex_token`
      plex_users=`echo $plex_xml | xmllint --format - | awk '/<MediaContainer size/ { print }' | cut -d \" -f2`
      echo $font_standard$mui_plex_streams$txt_align_right $plex_users
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
            plex_state_human="$plex_stream_state_buffer "
          fi
        fi
        plex_checkmusic=`echo $plex_stream | grep ' type="track"'`
        plex_bar_progress=$(($plex_inprogressms*100/$plex_durationms))
        if [[ "$plex_checkmusic" != "" ]]; then
          #plex_artiste=`echo $plex_stream | sed 's/.* originalTitle="//' | sed 's/".*//'`
          plex_artiste=`echo $plex_stream | sed 's/.* grandparentTitle="//' | sed 's/".*//'`
          plex_album=""
          if [[ "$plex_artiste" == "Various Artists" ]]; then
            plex_artiste=""
            plex_album=`echo $plex_stream | sed 's/.* parentTitle="//' | sed 's/".*//'`
          fi
          plex_song=`echo $plex_stream | sed 's/<Media .*//' | sed 's/.* title="//' | sed 's/".*//'`
          plex_music=`echo $plex_artiste$plex_album - $plex_song`
          echo -e "$font_extra\u25CF $font_standar${plex_music:0:30} $txt_align_right${plex_user:0:15}" >> ~/.conky/Temp/plex_music.log
          echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> ~/.conky/Temp/plex_music.log
        else
          plex_checkepisode=`echo $plex_stream | grep 'grandparentTitle='`
          if [[ "$plex_checkepisode" != "" ]]; then
            plex_serie=`echo $plex_stream | sed 's/.* grandparentTitle="//' | sed 's/".*//'`
            plex_episode=`echo $plex_stream | sed 's/summary=.*//' | sed 's/.* index="//' | sed 's/".*//'`
            plex_season=`echo $plex_stream | sed 's/.* parentTitle="Season //' | sed 's/".*//'`
            if [[ "$plex_transcode" == "transcode" ]]; then
              echo -e "$font_extra\u25CF $font_standard${plex_serie:0:22} ("$plex_season"x$(printf "%02d" $plex_episode)) $txt_align_right${plex_user:0:15}" >> ~/.conky/Temp/plex_transcode.log
              echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> ~/.conky/Temp/plex_transcode.log
            else
              echo -e "$font_extra\u25C9 $font_standard${plex_serie:0:22} ("$plex_season"x$(printf "%02d" $plex_episode)) $txt_align_right${plex_user:0:15}" >> ~/.conky/Temp/plex_direct.log
              echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> ~/.conky/Temp/plex_direct.log
            fi
          else
            plex_title=`echo $plex_stream | sed 's/ title="/|/g' | cut -d'|' -f2 | sed 's/".*//'`
            if [[ "$plex_transcode" == "transcode" ]]; then
              echo -e "$font_extra\u25CF $font_standard${plex_title:0:30} $txt_align_right${plex_user:0:16}" >> ~/.conky/Temp/plex_transcode.log
              echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> ~/.conky/Temp/plex_transcode.log
            else
              echo -e "$font_extra\u25C9 $font_standard${plex_title:0:30} $txt_align_right${plex_user:0:16}" >> ~/.conky/Temp/plex_direct.log
              echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> ~/.conky/Temp/plex_direct.log
            fi
          fi
        fi
#        plex_bar_progress=$(($plex_inprogressms*100/$plex_durationms))
#        echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> ~/.conky/Temp/plex.log
        let num=$num+1
      done
      cat ~/.conky/Temp/plex_transcode.log
      cat ~/.conky/Temp/plex_direct.log
      cat ~/.conky/Temp/plex_music.log
      rm ~/.conky/Temp/plex_transcode.log
      rm ~/.conky/Temp/plex_direct.log
      rm ~/.conky/Temp/plex_music.log
    else
      echo -e "\${font ${font_awesome_font}}$font_awesome_plex\${font}\${goto 35} ${font_title}$mui_plex_title \${hr 2}"
      echo ""
      echo -e "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_plex_error\$color"
    fi
    time2=`date +%s`
    duration_block=$(($time2-$time1))
    if [[ "$debug" == "yes" ]]; then
      if [[ $duration_block -lt 60 ]]; then
        echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Ss)"
      else
        echo -e "${font_standard}$mui_debug$(date -d@$duration_block -u +%Mm:%Ss)"
      fi
    fi
    echo "\${font}\${voffset -4}"
  fi
fi
