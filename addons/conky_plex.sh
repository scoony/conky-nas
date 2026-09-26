#!/bin/bash

#######################
## Generating script variables and basics
script_name=$(basename "$0" | cut -d'.' -f1)
script_name_cap=${script_name^^}
script_name_full=$(basename "$0")
script_bin="$0"
script_conf="$HOME/.config/.c.conf"
script_remote="https://raw.githubusercontent.com/Z0uZOU//main/$script_name_full"
script_folder="$HOME/.config/$script_name"
mkdir -p "$script_folder"


#######################
## Check if this script is running
lock_file="$script_folder/$script_name.lock"
exec 200>"$lock_file"

if ! flock -n 200; then
    echo "Script already running..."
    exit 1
fi

#######################
## Advanced command arguments
die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }
needs_long_arg() {
  if [[ -z "$OPTARG" ]] && (( OPTIND <= $# )); then
    OPTARG="${!OPTIND}"
    ((OPTIND++))
  fi
  needs_arg
}

#######################
## Script configuration

## Tautulli Config
settings_variables=( tautulli_ip tautulli_port tautulli_api tautulli_librairies plex_ip plex_port plex_token plex_extras )
touch "$script_conf"
chmod 600 "$script_conf"

for script_variable in "${settings_variables[@]}"; do
  if ! grep -qE "^[[:space:]]*${script_variable}[[:space:]]*=" "$script_conf"; then
    case "$script_variable" in
      *)
        printf '%s=""\n' "$script_variable" >> "$script_conf"
        ;;
    esac
  fi
done

# shellcheck source=/dev/null
source "$script_conf"

for command in curl jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Erreur: commande requise introuvable: %s\n' "$command" >&2
    exit 1
  fi
done






plex_state=`systemctl show -p SubState --value plexmediaserver`
plex_state="dead"
if [[ "$plex_state" != "dead" ]] || [[( "$plex_ip" != "" ) && ( "$plex_port" != "" ) && ( "$plex_token" != "" )]]; then
  echo -e "\${font ${font_awesome_font}}$font_awesome_plex\${font}\${goto 35} ${font_title}$mui_plex_title \${hr 2}"
  if [[ "$tautulli_ip" != "" ]] && [[ "$tautulli_port" != "" ]] && [[ "$tautulli_api" != "" ]] && [[ "$tautulli_librairies" != "" ]]; then
    echo -e "${font_standard}$mui_plex_libraries"
    tautulli_json=`curl --silent "http://$tautulli_ip:$tautulli_port/api/v2?apikey=$tautulli_api&cmd=get_libraries"`
    IFS='|' read -ra LIBS <<< "$tautulli_librairies"
    i=0
    line=""
    for lib in "${LIBS[@]}"; do
      section_type=$(echo "$tautulli_json" | jq -r --arg LIB "$lib" '.response.data[] | select(.section_name==$LIB) | .section_type')
      count=$(echo "$tautulli_json" | jq -r --arg LIB "$lib" '.response.data[] | select(.section_name==$LIB) | .count')
      child_count=$(echo "$tautulli_json" | jq -r --arg LIB "$lib" '.response.data[] | select(.section_name==$LIB) | .child_count // empty')
      parent_count=$(echo "$tautulli_json" | jq -r --arg LIB "$lib" '.response.data[] | select(.section_name==$LIB) | .parent_count // empty')
      case $(( i % 2 )) in
        0)
          # Colonne gauche
          case "$section_type" in
            movie)
              line="$lib > $count"
              ;;
            show)
              line="$lib > $count ($child_count)"
              ;;
            artist)
              line="$lib > $parent_count"
              ;;
            *)
              line="$lib > $count"
              ;;
          esac
        ;;
        1)
          # Colonne droite
          line+="${txt_align_right}"
          case "$section_type" in
            movie)
              line+="$count < $lib"
              ;;
            show)
              line+="($child_count) $count < $lib"
              ;;
            artist)
              line+="$parent_count < $lib"
              ;;
            *)
              line+="$count < $lib"
              ;;
          esac
          echo -e "${font_standard}${line}"
          line=""
          ;;
      esac
      ((i++))
    done
    # Affiche le reste si la dernière ligne n'est pas complète
    [[ -n "$line" ]] && echo -e "${font_standard}$line"
  fi
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
      plex_artiste=`echo $plex_stream | sed 's/.* grandparentTitle="//' | sed 's/".*//'`
      plex_album=""
      if [[ "$plex_artiste" == "Various Artists" ]]; then
        plex_artiste=""
        plex_album=`echo $plex_stream | sed 's/.* parentTitle="//' | sed 's/".*//'`
      fi
      plex_song=`echo $plex_stream | sed 's/<Media .*//' | sed 's/.* title="//' | sed 's/".*//'`
      plex_music=`echo $plex_artiste$plex_album - $plex_song`
      echo -e "$font_extra\uf111 $font_standard${plex_music:0:30} $txt_align_right${plex_user:0:15}" >> ~/.conky/Temp/plex_music.log
      echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> ~/.conky/Temp/plex_music.log
    else
      plex_checkepisode=`echo $plex_stream | grep 'grandparentTitle='`
      if [[ "$plex_checkepisode" != "" ]]; then
        plex_serie=`echo $plex_stream | sed 's/.* grandparentTitle="//' | sed 's/".*//'`
        plex_episode=`echo $plex_stream | sed 's/summary=.*//' | sed 's/.* index="//' | sed 's/".*//'`
        plex_season=`echo $plex_stream | sed 's/.* parentTitle="Season //' | sed 's/".*//'`
        if [[ "$plex_transcode" == "transcode" ]]; then
          echo -e "$font_extra\uf10C $font_standard${plex_serie:0:22} ("$plex_season"x$(printf "%02d" $plex_episode)) $txt_align_right${plex_user:0:15}" >> ~/.conky/Temp/plex_transcode.log
          echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> ~/.conky/Temp/plex_transcode.log
        else
          echo -e "$font_extra\uf111 $font_standard${plex_serie:0:22} ("$plex_season"x$(printf "%02d" $plex_episode)) $txt_align_right${plex_user:0:15}" >> ~/.conky/Temp/plex_direct.log
          echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> ~/.conky/Temp/plex_direct.log
        fi
      else
        plex_title=`echo $plex_stream | sed 's/ title="/|/g' | cut -d'|' -f2 | sed 's/".*//'`
        if [[ "$plex_transcode" == "transcode" ]]; then
          echo -e "$font_extra\uf10C $font_standard${plex_title:0:30} $txt_align_right${plex_user:0:16}" >> ~/.conky/Temp/plex_transcode.log
          echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> ~/.conky/Temp/plex_transcode.log
        else
          echo -e "$font_extra\uf111 $font_standard${plex_title:0:30} $txt_align_right${plex_user:0:16}" >> ~/.conky/Temp/plex_direct.log
          echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> ~/.conky/Temp/plex_direct.log
        fi
      fi
    fi
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
echo "\${font}\${voffset -4}"
