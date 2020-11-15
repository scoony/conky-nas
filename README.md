# conky-nas

This project was created to make the perfect conky for a Plex server (multi-language support).

![image](https://raw.githubusercontent.com/scoony/conky-nas/main/extras/conky-nas-demo.gif)

## Install not working yet

```bash
bash -c "$(wget -qO - https://raw.githubusercontent.com/scoony/conky-nas/main/extras/installer.sh)"
```

## Support

- hdd temp
- GPU usage and temp (nVIDIA)
- transmission-deamon
- plexmediaserver
- openvpn custom service (for permanent vpn)
- language (FR, ENG and DE)
- SMART Status check
- Pushover (for push notifications)
- checking services (restating them if sudo password is provided)

## Required (for manual install)

- libxml2-utils
- transmission-daemon (optional)
- transmission-cli (optional)
- plexmediaserver (optional)
- smartmontools
- hddtemp
- net-tools
- jq
- fonts-symbola
- fonts-font-awesome
- curl
- nVIDIA drivers (for GPU infos)

