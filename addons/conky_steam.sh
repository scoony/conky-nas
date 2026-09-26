#!/usr/bin/env bash

steam_api_key="YOUR_STEAM_API_KEY"
steam_id="YOUR_STEAM_ID"
steam_friends="STEAM_FRIEND_ID1 STEAM_FRIEND_ID2"

script_name=$(basename "$0" .sh)
script_folder="$HOME/.config/$script_name"
output_dir="$HOME/.conky"
output_file="$output_dir/$script_name.friends.ext"
lock_file="$script_folder/$script_name.lock"

mkdir -p "$script_folder" "$output_dir" || exit 1

exec 200>"$lock_file"
if ! flock -n 200; then
  printf "Script deja en cours d'execution.\n" >&2
  exit 1
fi

for command in curl jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Erreur: commande requise introuvable: %s\n' "$command" >&2
    exit 1
  fi
done

steam_id=${steam_id#"${steam_id%%[![:space:]]*}"}
steam_id=${steam_id%"${steam_id##*[![:space:]]}"}
if [[ ! "$steam_id" =~ ^[0-9]+$ ]]; then
  printf 'Erreur: steam_id doit être un SteamID64 numérique valide.\n' >&2
  exit 1
fi

friends_cache="$script_folder/friends_${steam_id}.json"
cache_max_age=43200
cache_is_valid=false

if [[ -f "$friends_cache" ]]; then
  cache_mtime=$(stat -c '%Y' "$friends_cache" 2>/dev/null || printf '0')
  cache_age=$(($(date +%s) - cache_mtime))
  if ((cache_age >= 0 && cache_age < cache_max_age)) &&
    jq -e '.friendslist.friends | type == "array"' "$friends_cache" >/dev/null 2>&1; then
    cache_is_valid=true
  fi
fi

if [[ "$cache_is_valid" == true ]]; then
  friends_response=$(<"$friends_cache")
else
  if ! friends_response=$(curl -fsS --max-time 20 --get \
    --data-urlencode "key=$steam_api_key" \
    --data-urlencode "steamid=$steam_id" \
    --data-urlencode 'relationship=friend' \
    'https://api.steampowered.com/ISteamUser/GetFriendList/v1/'); then
    printf "Erreur: impossible de récupérer la liste des amis Steam. Vérifiez que le profil et sa liste d'amis sont publics.\n" >&2
    exit 1
  fi

  if ! jq -e '.friendslist.friends | type == "array"' <<< "$friends_response" >/dev/null 2>&1; then
    printf "Erreur: liste d'amis Steam invalide ou privée.\n" >&2
    exit 1
  fi

  cache_tmp=$(mktemp "$script_folder/.friends_${steam_id}.XXXXXX") || exit 1
  printf '%s\n' "$friends_response" > "$cache_tmp"
  chmod 600 "$cache_tmp"
  mv -f "$cache_tmp" "$friends_cache"
fi

if [[ "$steam_friends" == "" ]]; then
  mapfile -t friend_ids < <(jq -r '.friendslist.friends[].steamid' <<< "$friends_response")
  declare -A players_by_id
else
  friend_ids+=($steam_friends)
fi

# GetPlayerSummaries accepte au maximum 100 SteamID par requête.
for ((offset = 0; offset < ${#friend_ids[@]}; offset += 100)); do
  batch=$(IFS=,; printf '%s' "${friend_ids[*]:offset:100}")
  if ! response=$(curl -fsS --max-time 20 --get \
    --data-urlencode "key=$steam_api_key" \
    --data-urlencode "steamids=$batch" \
    'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/'); then
    printf 'Erreur: impossible de récupérer le statut des amis Steam.\n' >&2
    exit 1
  fi

  if ! jq -e '.response.players | type == "array"' <<< "$response" >/dev/null 2>&1; then
    printf 'Erreur: réponse Steam invalide.\n' >&2
    exit 1
  fi

  while IFS= read -r player; do
    player_id=$(jq -r '.steamid // empty' <<< "$player")
    [[ -n "$player_id" ]] && players_by_id["$player_id"]=$player
  done < <(jq -c '.response.players[]' <<< "$response")
done

output_tmp=$(mktemp "$output_dir/.${script_name}.ext.XXXXXX") || exit 1
trap 'rm -f "$output_tmp"' EXIT

font_standard="\${font Noto Mono:normal:size=8}"
font_title="\${font Ubuntu:bold:size=10}"
font_awesome_font="Font Awesome 5 Pro:size=16"
font_awesome_friends="\uf0c0"

printf '%b\n' "\${font ${font_awesome_font}}${font_awesome_friends}\${font}\${goto 35} ${font_title}AMIS STEAM \${hr 2}" >> "$output_tmp"

playing_friends=()
online_friends=()

for friend_id in "${friend_ids[@]}"; do
  player=${players_by_id[$friend_id]:-}
  [[ -n "$player" ]] || continue
  personastate=$(jq -r '.personastate // 0' <<< "$player")
  game=$(jq -r '.gameextrainfo // empty' <<< "$player")

  [[ "$personastate" != '0' ]] || continue

  if [[ -n "$game" ]]; then
    playing_friends+=("$friend_id")
  else
    online_friends+=("$friend_id")
  fi
done

for friend_id in "${playing_friends[@]}" "${online_friends[@]}"; do
  player=${players_by_id[$friend_id]}
  personaname=$(jq -r '.personaname // .steamid // "Inconnu"' <<< "$player")
  game=$(jq -r '.gameextrainfo // empty' <<< "$player")

  personaname=${personaname//$'\n'/ }
  personaname=${personaname//$'\r'/ }
  personaname=${personaname//\\/}
  personaname=${personaname//\$/}
  game=${game//$'\n'/ }
  game=${game//$'\r'/ }
  game=${game//\\/}
  game=${game//\$/}

  if [[ -n "$game" ]]; then
    game_display="\${alignr}$game"
  else
    game_display=''
  fi

  printf '%b\n' "\${goto 6}${font_standard}${personaname}${game_display}" >> "$output_tmp"
done

echo "\${font}\${voffset -4}" >> "$output_tmp"

if [[ "${#friend_ids[@]}" == "0" ]]; then
  echo "Aucun ami connecté"
  rm "$output_file" >/dev/null 2>&1
else
  mv -f "$output_tmp" "$output_file"
fi
