# PNT-UDP By SHAN VPN

THIS IS A SCRIPT FOR AUTO INSTALLATION OF UDP (HYSTERIA SERVER) 

# Client app SHAN VPN

<p>
<a href="https://play.google.com/store/apps/details?id=com.shanvpn.vpnth"><img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png" height="100"></a>
</p>


# Installation
//ติดตั้งสคริป openvpn
```
apt update -y && apt upgrade -y && wget https://raw.githubusercontent.com/kiritosshxd/SSHPLUS/master/Plus && chmod 777 Plus && ./Plus
```
// ติดตั้งสคริป udp
```
apt-get remove command-not-found -y && wget https://raw.githubusercontent.com/hunmai/udp/refs/heads/main/install_agnudp.sh && chmod +x install_agnudp.sh; ./install_agnudp.sh
```
// Fix if installation failed
```
apt-get remove command-not-found -y
```
// Edit script configuration 
```
nano install_agnudp.sh
```

