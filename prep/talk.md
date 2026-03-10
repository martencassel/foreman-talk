# RHEL + Foreman Installation Guide

## Introduction
## Goals
## Target Audience
## Prerequisites

***

# RHEL Installation & Configuration

***

## Assumptions

```bash
grep -q "release 9.7" /etc/redhat-release && echo "RHEL 9.7" || echo "Not RHEL 9.7"
```

***

## 1. Configure Network (Static IP)

Replace values as needed:

```bash
nmcli con mod "$(nmcli -t -f NAME con show --active | head -n1)" \
  ipv4.addresses 192.168.0.5/24 \
  ipv4.gateway 192.168.0.1 \
  ipv4.dns "8.8.8.8 1.1.1.1" \
  ipv4.method manual

nmcli con up "$(nmcli -t -f NAME con show --active | head -n1)"
```

## 2. Disable Firewall (Optional)

```bash
systemctl disable firewalld --now
```

## 3. Update System & Install Basic Tools

```bash
sudo -i 
subscription-manager register --username marten.cassel@conoa.se --org 6698658
dnf update && dnf -y install vim
```

***

## 4. Set Hostname

```bash
hostnamectl set-hostname foreman.lab
echo "192.168.0.12 foreman.lab" | tee -a /etc/hosts > /dev/null
```

***

## 5. Add Repositories & Upgrade

```bash
sudo -i 

dnf clean all
dnf install -y https://yum.theforeman.org/releases/3.18/el9/x86_64/foreman-release.rpm
dnf install -y https://yum.puppet.com/puppet8-release-el-9.noarch.rpm
dnf repolist enabled
dnf upgrade
```

```bash
dnf install -y foreman-installer
```

***

## 6. Install AD Realm Plugin & Run Installer

```bash
dnf install -y rubygem-smart_proxy_realm_ad_plugin.noarch

foreman-installer \
  --foreman-proxy-realm=true \
  --foreman-proxy-realm-provider=ad
```

***

## 7. Check Logs

```bash
cat /var/log/foreman-proxy/proxy.log
cat /var/log/foreman-installer/foreman.log
```

***

## 8. Check Services

```bash
systemctl status foreman
systemctl status foreman-proxy
```

***

## 9. Example Realm AD Configuration File

**File:** `/etc/foreman-proxy/settings.d/realm_ad.yml`

```yaml
---
# Authentication for Kerberos-based Realms
:realm: EXAMPLE.COM

# Kerberos principal used to authenticate against Active Directory
:principal: realm-proxy@EXAMPLE.COM

# Path to the keytab used to authenticate against Active Directory
:keytab_path: /etc/foreman-proxy/realm_ad.keytab

# FQDN of the Domain Controller
:domain_controller: dc.example.com

# Optional: OU where the machine account shall be placed
#:ou: OU=Linux,OU=Servers,DC=example,DC=com

# Optional: Prefix for computername
#:computername_prefix: ''

# Optional: Hash hostname for computername
#:computername_hash: false

# Optional: Use FQDN as computername
#:computername_use_fqdn: false
```
***

```bash
sudo dnf install net-tools
netstat -tulpen


curl -k \
  --cert /etc/puppetlabs/puppet/ssl/certs/$(hostname -f).pem \
  --key /etc/puppetlabs/puppet/ssl/private_keys/$(hostname -f).pem \
  --cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem \
  https://foreman.lab:8443/v2/features|jq  
```
