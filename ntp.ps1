# Start and enable Windows Time service
#
Set-Service w32time -StartupType Automatic
Start-Service w32time

# Configure NTP server (example: pool.ntp.org)
# 
w32tm /config /update /manualpeerlist:"pool.ntp.org" /syncfromflags:manual

# Force immediate sync
#
w32tm /resync

w32tm /query /status
w32tm /query /configuration
w32tm /query /peers

