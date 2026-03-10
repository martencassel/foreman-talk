#!/bin/bash


nmcli connection modify eth1 ipv4.ignore-auto-dns yes
nmcli connection modify eth1 ipv4.dns ""

nmcli conection modify eth0 ipv4.dns "172.31.26.175"
nmcli connection modify eth0 ipv4.ignore-auto-dns yes

nmcli connection down eth0; nmcli connection up eth0
nmcli connection down eth1; nmcli connection up eth1

adcli info example.com

realm join dc01.example.com -U administrator --membership-software=adcli -vvv

realm list

dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install msktutil -y

adcli create-user foreman-proxy --domain=example.com
adcli passwd-user --domain=example.com foreman-proxy

Password for Administrator@EXAMPLE.COM:
Password for foreman-proxy:


[root@foreman ~]# ktutil
ktutil:  addent -password -p foreman-proxy@EXAMPLE.COM -k 1 -e aes256-cts-hmac-sha1-96
Password for foreman-proxy@EXAMPLE.COM:
ktutil:  addent -password -p foreman-proxy@EXAMPLE.COM -k 1 -e aes128-cts-hmac-sha1-96
Password for foreman-proxy@EXAMPLE.COM:
ktutil:  wkt /tmp/realm.keytab
ktutil:  quit
[root@foreman ~]# cat /tmp/realm.keytab

kinit -kt /tmp/realm.keytab foreman-proxy@EXAMPLE.COM

