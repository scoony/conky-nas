# conky-nas

This project was created to make the perfect conky for a Plex server (multi-language support).

####Install: (not working yet)
```
bash -c "$(wget -qO - https://raw.githubusercontent.com/scoony/conky-nas/main/extras/installer.sh)"
```

#### Support:
- transmission-deamon
- plexmediaserver
- openvpn service

#### Required:
- apt install libxml2-utils
- install transmission-remote
- install ifconfig

#### Work done:
- autodetect HDD
- autodetect plex-token
- autodetect net-adapter
- check if reboot is required
- multilanguage done
- autodetect if network is secured thru VPN and adapt the display
- autodetect plexmediaserver and transmission-daemon and activate display accordingly
- humanized speeds in transmission
- remote plex is done

#### To-do list:
- chercher les ips en dehors de conky et n'afficher que dans le echo
- comparer les ip et message à la reboot
- graph cpu en gris comme net graph
- vérifier si la mise en page est la meme sans avatar
