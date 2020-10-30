# conky-nas

This project was created to make the perfect conky for a Plex server (multi-language support).

![image](https://raw.githubusercontent.com/scoony/conky-nas/main/extras/conky-nas-demo.gif)

#### Install: (not working yet)
```
bash -c "$(wget -qO - https://raw.githubusercontent.com/scoony/conky-nas/main/extras/installer.sh)"
```

#### Support:
- transmission-deamon
- plexmediaserver
- openvpn custom service (for permanent vpn)
- language (FR, ENG and DE)

#### Required (for manual install):
- libxml2-utils
- transmission-cli
- net-tools
- jq

#### Work done:
- autodetect HDD
- autodetect plex-token
- autodetect net-adapter
- check if reboot is required
- multilanguage done
- autodetect if network is secured thru VPN and adapt the display
- autodetect plexmediaserver and transmission-daemon (activate display accordingly)
- humanized speeds in transmission
- remote plex is done
- de language added
- the size and location of avatar can be set in the conf

#### To-do list:
- chercher les ips en dehors de conky et n'afficher que dans le echo
- comparer les ip et message à la reboot
- graph cpu en gris comme net graph
- vérifier si la mise en page est la meme sans avatar
