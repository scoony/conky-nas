#!/bin/bash

#######################
## Scoony Fix because Ubuntu 22.04 doesn't use the proper version of nodejs, nodejs v16+ required
## nodejs manual install required and "use" the installed version
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 24


#######################
## Generating script variables and basics
script_name=$(basename "$0" | cut -d'.' -f1)
script_name_cap=${script_name^^}
script_name_full=$(basename "$0")
script_bin="$0"
script_conf="$HOME/.config/$script_name/$script_name.conf"
script_remote="https://raw.githubusercontent.com/scoony/conky-nas/main/$script_name_full"
script_folder="$HOME/.config/$script_name"


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
settings_variables=( servers push_token_app push_target )
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

update_server_list() {
  local action=$1
  local requested_server=$2
  local server found=0 new_value config_tmp line written=0
  local -a current_servers updated_servers

  if [[ ! "$requested_server" =~ ^[[:alnum:]_.+-]+$ ]]; then
    die "Invalid server name: $requested_server"
  fi

  IFS='|' read -r -a current_servers <<< "${servers:-}"
  for server in "${current_servers[@]}"; do
    [[ -n "$server" ]] || continue
    if [[ "${server,,}" == "${requested_server,,}" ]]; then
      found=1
      [[ "$action" == 'remove' ]] && continue
    fi
    updated_servers+=("$server")
  done

  if [[ "$action" == 'add' ]]; then
    if (( found )); then
      echo "servers already contains: $requested_server"
      return 0
    fi
    updated_servers+=("$requested_server")
  elif (( ! found )); then
    echo "servers does not contain: $requested_server"
    return 0
  elif (( ${#updated_servers[@]} == 0 )); then
    die 'At least one server must remain in servers'
  fi

  new_value=$(IFS='|'; echo "${updated_servers[*]}")
  config_tmp=$(mktemp "$script_folder/.${script_name}.conf.XXXXXX") || die 'Unable to create config temporary file'

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*servers[[:space:]]*= ]]; then
      if (( ! written )); then
        printf 'servers="%s"\n' "$new_value" >> "$config_tmp"
        written=1
      fi
    else
      printf '%s\n' "$line" >> "$config_tmp"
    fi
  done < "$script_conf"

  chmod 600 "$config_tmp"
  mv -f "$config_tmp" "$script_conf"
  echo "servers updated: $new_value"
}

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
      echo ' --add-server=[name]                  : add a server to servers'
      echo ' --remove-server=[name]               : remove a server from servers'
      exit 0
      ;;
    add-server)
      needs_long_arg "$@"
      update_server_list add "$OPTARG"
      exit 0
      ;;
    remove-server)
      needs_long_arg "$@"
      update_server_list remove "$OPTARG"
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

if [[ -z "${servers:-}" ]]; then
  die "servers is empty in $script_conf"
fi

SERVER_LIST_URL="https://cdn2.arkdedicated.com/servers/asa/officialserverlist.json"
OUTPUT_DIR="$HOME/.conky"
OUTPUT_FILE="$OUTPUT_DIR/$script_name.games.ext"
STATE_DIR="$script_folder/state"
QUERY_TIMEOUT=10
QUERY_ATTEMPTS=2

font_standard="\${font Noto Mono:normal:size=8}"
font_title="\${font Ubuntu:bold:size=10}"
font_awesome_font="Font Awesome 5 Pro:size=16"
font_awesome_ark="\uf8bc"
mui_ark_title="ARK SURVIVAL ASCENDED"
txt_align_right="\${alignr}"
smart_glyph="\uf0c8"

for command in curl jq gamedig timeout; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Erreur: commande requise introuvable: %s\n' "$command" >&2
    exit 1
  fi
done

if ! mkdir -p "$OUTPUT_DIR" "$STATE_DIR"; then
  printf 'Erreur: impossible de créer les répertoires de sortie ou d’état.\n' >&2
  exit 1
fi

server_list=$(mktemp) || exit 1
output_tmp=$(mktemp "$OUTPUT_DIR/.ark_servers_monitor.ext.XXXXXX") || exit 1
trap 'rm -f "$server_list" "$output_tmp"' EXIT

echo -e "\${font ${font_awesome_font}}${font_awesome_ark}\${font}\${goto 35} ${font_title}${mui_ark_title} \${hr 2}" >> "$output_tmp"

if ! curl -fsSL --retry 2 --connect-timeout 5 --max-time 30 "$SERVER_LIST_URL" -o "$server_list"; then
  printf 'Erreur: impossible de récupérer la liste officielle des serveurs.\n' >&2
  exit 1
fi

if ! jq -e 'type == "array"' "$server_list" >/dev/null 2>&1; then
  printf 'Erreur: la liste officielle reçue est invalide.\n' >&2
  exit 1
fi

format_duration() {
  local seconds=$1
  local days hours minutes

  (( seconds < 0 )) && seconds=0
  days=$((seconds / 86400))
  hours=$((seconds % 86400 / 3600))
  minutes=$((seconds % 3600 / 60))

  if (( days > 0 )); then
    printf '%dj %dh' "$days" "$hours"
  elif (( hours > 0 )); then
    printf '%dh %02dmin' "$hours" "$minutes"
  else
    printf '%dmin' "$minutes"
  fi
}

format_push_duration() {
  local seconds=$1
  local days hours minutes

  (( seconds < 0 )) && seconds=0
  days=$((seconds / 86400))
  hours=$((seconds % 86400 / 3600))
  minutes=$((seconds % 3600 / 60))

  if (( days > 0 )); then
    printf '%d j %d h %d m' "$days" "$hours" "$minutes"
  elif (( hours > 0 )); then
    printf '%d h %d m' "$hours" "$minutes"
  else
    printf '%d m' "$minutes"
  fi
}

send_push() {
  local title=$1
  local message=$2
  local targets recipient
  local -a recipients

  [[ -n "${push_token_app:-}" && -n "${push_target:-}" ]] || return 0

  targets=${push_target//,/|}
  targets=${targets//;/|}
  IFS='|' read -r -a recipients <<< "$targets"

  for recipient in "${recipients[@]}"; do
    recipient=${recipient#"${recipient%%[![:space:]]*}"}
    recipient=${recipient%"${recipient##*[![:space:]]}"}
    [[ -n "$recipient" ]] || continue

    curl --silent --show-error --fail --max-time 20 \
      --form-string "token=$push_token_app" \
      --form-string "user=$recipient" \
      --form-string "title=$title" \
      --form-string "message=$message" \
      --form-string 'html=1' \
      https://api.pushover.net/1/messages.json >/dev/null ||
      printf 'Erreur: notification Pushover non envoyée à %s.\n' "$recipient" >&2
  done
}

show_conky_status() {
  local name=$1
  local status=$2
  local smart_color=$3
  local status_output=''

  [[ -n "$status" ]] && status_output="${txt_align_right}${status}"
  printf '%b\n' "\${offset -5}\${voffset 2}\${font FontAwesome:size=5}\${color $smart_color}$smart_glyph\${color}\${voffset -3}\${goto 6}${font_standard}${name}${status_output}" >> "$output_tmp"
}

show_offline() {
  local name=$1
  local state_file=$2
  local status_file=$3
  local now offline_since duration push_message previous_status=''

  if [[ -r "$status_file" ]]; then
    read -r previous_status < "$status_file"
  elif [[ -f "$state_file" ]]; then
    previous_status='offline'
  fi

  now=$(date +%s)
  if [[ -r "$state_file" ]]; then
    read -r offline_since < "$state_file"
  else
    offline_since=$now
  fi

  [[ "$offline_since" =~ ^[0-9]+$ ]] || offline_since=$now
  printf '%s\n' "$offline_since" > "$state_file"
  printf 'offline\n' > "$status_file"
  if [[ "$previous_status" == 'online' ]]; then
    printf -v push_message '<b>%s</b>\n\n<b>Statut</b> : OFFLINE' "$name"
    send_push "[ARK] Serveur OFFLINE" "$push_message"
  fi
  duration=$(format_duration "$((now - offline_since))")
  show_conky_status "$name" "$duration" "red"
}

show_online() {
  local name=$1
  local players=$2
  local max_players=$3
  local state_file=$4
  local status_file=$5
  local previous_status='' now offline_since push_duration restored_at push_message

  if [[ -r "$status_file" ]]; then
    read -r previous_status < "$status_file"
  elif [[ -f "$state_file" ]]; then
    previous_status='offline'
  fi

  if [[ "$previous_status" == 'offline' ]]; then
    now=$(date +%s)
    if [[ -r "$state_file" ]]; then
      read -r offline_since < "$state_file"
    else
      offline_since=$now
    fi
    [[ "$offline_since" =~ ^[0-9]+$ ]] || offline_since=$now
    push_duration=$(format_push_duration "$((now - offline_since))")
    restored_at=$(date '+%d/%m/%Y %H:%M')
    printf -v push_message '<b>%s</b>\n\n<b>Statut</b> : ONLINE\n<b>Indisponibilité</b> : %s\n<b>Rétabli</b> : %s' \
      "$name" "$push_duration" "$restored_at"
    send_push "[ARK] Serveur ONLINE" "$push_message"
  fi
  rm -f "$state_file"
  printf 'online\n' > "$status_file"
  show_conky_status "$name" "$players/$max_players" "lightgreen"
}

IFS='|' read -r -a server_names <<< "$servers"
for name in "${server_names[@]}"; do
  [[ -z "$name" ]] && continue
  state_name=${name//[^[:alnum:]_.-]/_}
  state_file="$STATE_DIR/$state_name.offline"
  status_file="$STATE_DIR/$state_name.status"
  server_data=$(jq -r --arg name "$name" 'first(.[] | select(.Name == $name)) as $server | [$server.IP, ($server.Port | tostring)] | @tsv' "$server_list")
  if [[ -z "$server_data" ]]; then
    show_offline "$name" "$state_file" "$status_file"
    continue
  fi
  IFS=$'\t' read -r ip port <<< "$server_data"
  result=''
  for ((attempt = 1; attempt <= QUERY_ATTEMPTS; attempt++)); do
    if result=$(timeout "${QUERY_TIMEOUT}s" gamedig --type asa "$ip:$port" 2>/dev/null) && jq -e '.numplayers >= 0 and .maxplayers > 0' <<< "$result" >/dev/null 2>&1; then
      break
    fi
    result=''
  done
  if [[ -n "$result" ]]; then
    players=$(jq -r '.numplayers' <<< "$result")
    max_players=$(jq -r '.maxplayers' <<< "$result")
    show_online "$name" "$players" "$max_players" "$state_file" "$status_file"
  else
    show_offline "$name" "$state_file" "$status_file"
  fi
done

echo "\${font}\${voffset -4}" >> "$output_tmp"
mv -f "$output_tmp" "$OUTPUT_FILE"
