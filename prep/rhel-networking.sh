sudo nmcli connection modify eth0 ipv4.route-metric 102
sudo nmcli connection modify eth1 ipv4.route-metric 101
sudo nmcli connection down eth0
sudo nmcli connection up eth0
sudo nmcli connection down eth1
sudo nmcli connection up eth1

sudo nmcli connection show eth0 | grep ipv4.method


[marten@localhost ~]$ ip route
default via 192.168.0.1 dev eth1 proto dhcp src 192.168.0.17 metric 101
default via 172.22.48.1 dev eth0 proto dhcp src 172.22.53.208 metric 102
172.22.48.0/20 dev eth0 proto kernel scope link src 172.22.53.208 metric 102
192.168.0.0/24 dev eth1 proto kernel scope link src 192.168.0.17 metric 101


sudo -i

###############################
# Convert eth1 to static IP
###############################
nmcli connection modify eth1 ipv4.addresses 192.168.0.18/24
nmcli connection modify eth1 ipv4.gateway 192.168.0.1
nmcli connection modify eth1 ipv4.method manual
nmcli connection modify eth1 ipv6.method ignore

###############################
# Convert eth0 to static IP
###############################
nmcli connection modify eth0 ipv4.addresses 172.22.50.58/20
nmcli connection modify eth0 ipv4.gateway 172.22.48.1
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv6.method ignore

###############################
# (Optional) DNS configuration
###############################
nmcli connection modify eth0 ipv4.dns "8.8.8.8 1.1.1.1"
nmcli connection modify eth0 ipv4.ignore-auto-dns yes
nmcli connection down eth0 && sudo nmcli connection up eth0
nmcli connection down eth1 && sudo nmcli connection up eth1
dnf update

###############################
# Apply changes
###############################
nmcli connection down eth1 && nmcli connection up eth1
nmcli connection down eth0 && nmcli connection up eth0

reboot



