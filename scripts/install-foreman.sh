#!/bin/bash

sudo systemctl stop firewalld --now
sudo subscription-manager register --username marten.cassel@conoa.se --org 6698658
sudo dnf update -y
sudo dnf -y install vim adcli nmap net-tools

sudo hostname set-hostname foreman.EXAMPLE.COM
echo "172.31.16.1 foreman.EXAMPLE.COM" | tee -a /etc/hosts > /dev/null

dnf clean all
dnf install -y https://yum.theforeman.org/releases/3.18/el9/x86_64/foreman-release.rpm
dnf install -y https://yum.puppet.com/puppet8-release-el-9.noarch.rpm
dnf repo list enabled
dnf upgrade

dnf install -y foreman-installer
dnf install -y rubygem-smart_proxy_realm_ad_plugin.noarch

foreman-installer \
     --foreman-proxy-realm=true \
     --foreman-proxy-realm-provider=ad

systemctl status foreman
systemctl status foreman-proxy

cat /var/log/foreman-proxy/proxy.log
cat /var/log/foreman-installer/foreman.log

curl -k \
     --cert /etc/puppetlabs/puppet/ssl/certs/$(hostname -f).pem \
     --key /etc/puppetlabs/puppet/ssl/private_keys/$(hostname -f).pem \
     --cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem \
     https://foreman.lab:8443/v2/features/jq

