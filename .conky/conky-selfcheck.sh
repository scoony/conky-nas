#!/bin/bash

## CONFIG
#########
font_title="\${font Ubuntu:bold:size=10}"
font_standard="\${font Noto Mono:normal:size=8}"
font_extra="\${font sans-serif:normal:size=8}"
txt_align_right="\${alignr}"
txt_align_center="\${alignc}"
push_token_app=""
push_destinataire=""

user_pass=""
services_list=""


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

push-message() {
  push_title=$1
  push_content=$2
  if [ -n "$push_destinataire" ]; then
    curl -s \
      --form-string "token=$push_token_app" \
      --form-string "user=$push_destinataire" \
      --form-string "title=$push_title" \
      --form-string "message=$push_content" \
      --form-string "html=1" \
      --form-string "priority=0" \
      https://api.pushover.net/1/messages.json > /dev/null
  fi
}


if [[ ! -d ~/.conky/pushover ]]; then mkdir -p ~/.conky/pushover; fi
if [[ "$push_token_app" == "" ]] || [[ "$push_destinataire" == "" ]]; then
  echo "\${font FontAwesome:size=16}\${font} ${font_title}PUSHOVER \${hr 2}"
  echo ""
  echo "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_pushover_error\$color"
  echo "\${font}\${voffset -4}"
fi

echo "\${font FontAwesome:size=16}\${font} ${font_title}$mui_services_title \${hr 2}"
for myservice in $services_list; do
  service_mystate=`systemctl show -p SubState --value $myservice`
  if [[ "$service_mystate" != "dead" ]]; then
    service_color=""
    if [[ -f ~/.conky/pushover/$myservice ]]; then
      rm ~/.conky/pushover/$myservice
      myservice_message="Le service $myservice était OK lors de la dernière vérification"
      push-message "Selfcheck Service" "$myservice_message"
    fi
  else
    service_color="red"
    if [[ ! -f ~/.conky/pushover/$myservice ]]; then
      touch ~/.conky/pushover/$myservice
      myservice_message="Le service $myservice était HS lors de la dernière vérification"
      push-message "Selfcheck Service" "$myservice_message"
    fi
  fi
  echo "${font_standard}$myservice:${txt_align_right}\${color $service_color}\${execi 5 systemctl is-active $myservice}\$color"
done
echo "\${font}\${voffset -4}"