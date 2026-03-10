# Install Foreman VM
# External Network NIC (Only for updates from internet)
# Internal Network NIC (for inter communication with Active Directory)
# Set Static IP addresses on both nics


sudo -i 

# Convert eth0 to static ip (Internal Network)
nmcli connection modify eth0 ipv4.addresses 172.31.18.203/20
nmcli connection modify eth0 ipv4.gateway 172.31.16.1
nmcli connection modify eth0 ipv4.method manual
nmcli connection modify eth0 ipv6.method ignore

# Convert eth1 to static ip (External Network)
nmcli connection modify eth1 ipv4.addresses 192.168.0.26/24
nmcli connection modify eth1 ipv4.gateway 192.168.0.1
nmcli connection modify eth1 ipv4.method manual
nmcli connection modify eth1 ipv6.method ignore

nmcli connection modify eth1 ipv4.dns "8.8.8.8 1.1.1.1"
nmcli connection modify eth1 ipv4.ignore-auto-dns yes

nmcli connection down eth0
nmcli connection up eth0

nmcli connection down eth1
nmcli connection up eth1

# Routes

nmcli connection modify eth0 ipv4.route-metric 102
nmcli connection modify eth1 ipv4.route-metric 101
nmcli connection down eth0
nmcli connection up eth0
nmcli connection down eth1
ncmli connection up eth1
