New-VM -Name "rhel2" -Generation 2 -MemoryStartupBytes 8GB `
       -NewVHDPath "$HOME\rhel2.vhdx" `
       -NewVHDSizeBytes 20GB -SwitchName "Default Switch"

# Add second NIC
Add-VMNetworkAdapter -VMName "rhel2" -SwitchName "External" -Name "ExternalNIC"

# Disable Secure Boot + attach ISO
Set-VMFirmware -VMName "rhel2" -EnableSecureBoot Off
Add-VMDvdDrive -VMName "rhel2"
Set-VMDvdDrive -VMName "rhel2" -Path "$HOME\Downloads\rhel-9.7-x86_64-dvd.iso"

# Set boot order: DVD → HDD → NIC
$dvd = Get-VMDvdDrive -VMName "rhel2"
$hdd = Get-VMHardDiskDrive -VMName "rhel2"
$nic = Get-VMNetworkAdapter -VMName "rhel2" | Select-Object -Last 1   # NIC last

Set-VMFirmware -VMName "rhel2" -BootOrder $dvd,$hdd,$nic

# Start the VM
Start-VM -VMName "rhel2"

# Delete Remove-VM -VMName rhel2 del C:\users\U01MCA\vms\rhel2.vhdx
