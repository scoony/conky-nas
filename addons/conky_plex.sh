#!/bin/bash

#######################
## Generating script variables and basics
script_name=$(basename "$0" | cut -d'.' -f1)
script_name_cap=${script_name^^}
script_name_full=$(basename "$0")
script_bin="$0"
script_conf="$HOME/.conky/conky-nas.conf"
script_remote="https://raw.githubusercontent.com/scoony/conky-nas/main/addons/$script_name_full"
script_folder="$HOME/.config/$script_name"
output_file="$HOME/.conky/$script_name.apps.ext"
mkdir -p "$script_folder"

#### Check local language and apply MUI
os_language=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
if [[ -f "$HOME/.conky/MUI/$os_language.lang" ]]; then
  source "$HOME/.conky/MUI/$os_language.lang"
else
  source "$HOME/.conky/MUI/en.lang"
fi

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

manage_cron() {
  local action=${1:-status}
  local cron_tmp cron_line cron_found=0 cron_enabled=0

  command -v crontab >/dev/null 2>&1 || die 'crontab is not installed'
  cron_tmp=$(mktemp "$script_folder/.${script_name}.cron.XXXXXX") || die 'Unable to create cron temporary file'
  crontab -l > "$cron_tmp" 2>/dev/null || :

  while IFS= read -r cron_line; do
    if [[ "$cron_line" == *"$script_name"* ]]; then
      cron_found=1
      [[ "$cron_line" =~ ^[[:space:]]*# ]] || cron_enabled=1
    fi
  done < "$cron_tmp"

  case "$action" in
    status|'')
      if (( ! cron_found )); then
        echo 'Script is not present in cron'
      elif (( cron_enabled )); then
        echo 'Script is currently enabled in cron'
      else
        echo 'Script is currently disabled in cron'
      fi
      ;;
    enable)
      if (( ! cron_found )); then
        rm -f "$cron_tmp"
        die 'Script is not present in cron'
      fi
      sed -i -E "/$script_name/s/^[[:space:]]*#[[:space:]]?//" "$cron_tmp"
      crontab "$cron_tmp" || { rm -f "$cron_tmp"; die 'Unable to update cron'; }
      echo 'Script enabled in cron'
      ;;
    disable)
      if (( ! cron_found )); then
        rm -f "$cron_tmp"
        die 'Script is not present in cron'
      fi
      sed -i -E "/$script_name/{/^[[:space:]]*#/!s/^/#/;}" "$cron_tmp"
      crontab "$cron_tmp" || { rm -f "$cron_tmp"; die 'Unable to update cron'; }
      echo 'Script disabled in cron'
      ;;
    *)
      rm -f "$cron_tmp"
      die "Invalid status action: $action (expected: status, enable or disable)"
      ;;
  esac

  rm -f "$cron_tmp"
}

#######################
## Advanced command arguments
while getopts 'eush-:' OPT; do
  if [[ "$OPT" == '-' ]]; then
    OPT="${OPTARG%%=*}"
    OPTARG="${OPTARG#"$OPT"}"
    OPTARG="${OPTARG#=}"
  fi

  case "$OPT" in
    h|help)
      echo -e "\033[1m$script_name_cap - help\033[0m"
      echo
      echo "Usage: $script_bin [option]"
      echo
      echo 'Available options:'
      echo ' -h or --help                         : this help menu'
      echo ' -u or --update                       : update this script'
      echo ' -e [editor] or --edit-config[=editor]: edit config file (default: nano)'
      echo ' -s [action] or --status[=action]     : status/enable/disable the script in cron'
      exit 0
      ;;
    u|update)
      echo -e "\033[1m$script_name_cap - Update initiated\033[0m"
      read -r -n 1 -p 'Do you want to proceed [y/N]: ' answer
      echo
      if [[ "$answer" == [yY] ]]; then
        this_script=$(realpath -s "$0")
        update_tmp=$(mktemp "$script_folder/.${script_name}.update.XXXXXX") || die 'Unable to create update temporary file'
        if curl -fsSL --max-time 20 "$script_remote" -o "$update_tmp"; then
          chmod --reference="$this_script" "$update_tmp" 2>/dev/null || chmod +x "$update_tmp"
          mv -f "$update_tmp" "$this_script"
          echo 'Update completed'
        else
          rm -f "$update_tmp"
          die 'Script unavailable online'
        fi
      else
        echo 'Nothing was done'
      fi
      exit 0
      ;;
    e|edit-config)
      editor=${OPTARG:-}
      if [[ -z "$editor" && $OPTIND -le $# && "${!OPTIND}" != -* ]]; then
        editor=${!OPTIND}
      fi
      editor=${editor:-nano}
      command -v "$editor" >/dev/null 2>&1 || die "There is no software called '$editor' installed"
      "$editor" "$script_conf"
      exit 0
      ;;
    s|status)
      status_action=${OPTARG:-}
      if [[ -z "$status_action" && $OPTIND -le $# && "${!OPTIND}" != -* ]]; then
        status_action=${!OPTIND}
      fi
      manage_cron "${status_action:-status}"
      exit 0
      ;;
    ??*) die "Illegal option --$OPT" ;;
    ?) exit 2 ;;
  esac
done
shift $((OPTIND - 1))

#######################
## Dependencies
for command in curl jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Erreur: commande requise introuvable: %s\n' "$command" >&2
    exit 1
  fi
done

output_tmp=$(mktemp "$script_folder/.conky_plex.ext.XXXXXX") || exit 1
output_tmp_transcode=$(mktemp "$script_folder/.conky_plex_transcode.ext.XXXXXX") || exit 1
output_tmp_direct=$(mktemp "$script_folder/.conky_plex_direct.ext.XXXXXX") || exit 1
output_tmp_music=$(mktemp "$script_folder/.conky_plex_music.ext.XXXXXX") || exit 1
trap 'rm -f "$output_tmp" "$output_tmp_transcode" "$output_tmp_direct" "$output_tmp_music"' EXIT
plex_state=`systemctl show -p SubState --value plexmediaserver`
if [[ "$plex_state" != "dead" ]] || [[( "$plex_ip" != "" ) && ( "$plex_port" != "" ) && ( "$plex_token" != "" )]]; then
  echo -e "\${font ${font_awesome_font}}$font_awesome_plex\${font}\${goto 35} ${font_title}$mui_plex_title \${hr 2}" >> "$output_tmp"
  if [[ "$tautulli_ip" != "" ]] && [[ "$tautulli_port" != "" ]] && [[ "$tautulli_api" != "" ]] && [[ "$tautulli_librairies" != "" ]]; then
    echo -e "${font_standard}$mui_plex_libraries" >> "$output_tmp"
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
          echo -e "${font_standard}${line}" >> "$output_tmp"
          line=""
          ;;
      esac
      ((i++))
    done
    # Affiche le reste si la dernière ligne n'est pas complète
    [[ -n "$line" ]] && echo -e "${font_standard}$line" >> "$output_tmp"
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
    echo $font_standard"$mui_plexip_used"$txt_align_right$plexip_used"" >> "$output_tmp"
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
      echo $font_standard"$mui_plex_pid $plex_pid ($plex_ram_used)"$txt_align_right"$mui_plex_prlimit $plex_prlimit" >> "$output_tmp"
    else
      echo $font_standard"$mui_plex_pid $plex_pid"$txt_align_right"$mui_plex_prlimit $plex_prlimit" >> "$output_tmp"
    fi
  fi
  plex_xml=`curl --silent http://$plex_ip:$plex_port/status/sessions?X-Plex-Token=$plex_token`
  plex_users=`echo $plex_xml | xmllint --format - | awk '/<MediaContainer size/ { print }' | cut -d \" -f2`
  echo $font_standard$mui_plex_streams$txt_align_right $plex_users >> "$output_tmp"
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
      echo -e "$font_extra\uf111 $font_standard${plex_music:0:30} $txt_align_right${plex_user:0:15}" >> "$output_tmp_music"
      echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> "$output_tmp_music"
    else
      plex_checkepisode=`echo $plex_stream | grep 'grandparentTitle='`
      if [[ "$plex_checkepisode" != "" ]]; then
        plex_serie=`echo $plex_stream | sed 's/.* grandparentTitle="//' | sed 's/".*//'`
        plex_episode=`echo $plex_stream | sed 's/summary=.*//' | sed 's/.* index="//' | sed 's/".*//'`
        plex_season=`echo $plex_stream | sed 's/.* parentTitle="Season //' | sed 's/".*//'`
        if [[ "$plex_transcode" == "transcode" ]]; then
          echo -e "$font_extra\uf10C $font_standard${plex_serie:0:22} ("$plex_season"x$(printf "%02d" $plex_episode)) $txt_align_right${plex_user:0:15}" >> "$output_tmp_transcode"
          echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> "$output_tmp_transcode"
        else
          echo -e "$font_extra\uf111 $font_standard${plex_serie:0:22} ("$plex_season"x$(printf "%02d" $plex_episode)) $txt_align_right${plex_user:0:15}" >> "$output_tmp_direct"
          echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> "$output_tmp_direct"
        fi
      else
        plex_title=`echo $plex_stream | sed 's/ title="/|/g' | cut -d'|' -f2 | sed 's/".*//'`
        if [[ "$plex_transcode" == "transcode" ]]; then
          echo -e "$font_extra\uf10C $font_standard${plex_title:0:30} $txt_align_right${plex_user:0:16}" >> "$output_tmp_transcode"
          echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> "$output_tmp_transcode"
        else
          echo -e "$font_extra\uf111 $font_standard${plex_title:0:30} $txt_align_right${plex_user:0:16}" >> "$output_tmp_direct"
          echo -e $font_standard$plex_inprogress" / "$plex_duration  $plex_state_human\${voffset 1}\${execbar echo $plex_bar_progress} >> "$output_tmp_direct"
        fi
      fi
    fi
    let num=$num+1
  done
  cat "$output_tmp_transcode" >> "$output_tmp"
  cat "$output_tmp_direct" >> "$output_tmp"
  cat "$output_tmp_music" >> "$output_tmp"
  echo "\${font}\${voffset -4}" >> "$output_tmp"
#  rm "$output_tmp_transcode"
#  rm "$output_tmp_direct"
#  rm "$output_tmp_music"
else
  echo -e "\${font ${font_awesome_font}}$font_awesome_plex\${font}\${goto 35} ${font_title}$mui_plex_title \${hr 2}" >> "$output_tmp"
  echo "" >> "$output_tmp"
  echo -e "\${execbar 14 echo 100}${font_standard}\${goto 0}\${voffset -1}${txt_align_center}\${color black}$mui_plex_error\$color" >> "$output_tmp"
  echo "\${font}\${voffset -4}" >> "$output_tmp"
fi

mv -f "$output_tmp" "$output_file"