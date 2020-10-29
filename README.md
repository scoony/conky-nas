# conky-nas

This project was created to make the perfect conky for a Plex server.

#### Support:
- transmission-deamon
- plexmediaserver
- openvpn service

#### Required:
- apt install libxml2-utils
- install transmission-remote
- install ifconfig

#### Work done
- autodetect HDD
- autodetect plex-token
- autodetect net-adapter
- check if reboot is required
- multilanguage done
- autodetect if network is secured thru VPN and adapt the display
- autodetect plexmediaserver and transmission-daemon services (to display only if required)
- humanization of transmission speeds
- remote plex server is handled
- remote transmission server is handled

#### To-do list
- chercher les ips en dehors de conky et n'afficher que dans le echo
- comparer les ip et message à la reboot
- graph cpu en gris comme net graph
- vérifier si la mise en page est la meme sans avatar
