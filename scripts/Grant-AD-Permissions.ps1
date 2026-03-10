Import-Module ActiveDirectory

$OU   = "OU=Servers,DC=example,DC=com"
$User = "EXAMPLE\foreman-proxy"

# Get the OU object
$ouObject = Get-ADOrganizationalUnit -Identity $OU

# Build the access rule
$identity = New-Object System.Security.Principal.NTAccount($User)
$guidComputer = [Guid]"bf967a86-0de6-11d0-a285-00aa003049e2"   # SchemaIDGUID for 'computer' class

$ruleCreate = New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
    ($identity,
     "CreateChild",
     "Allow",
     $guidComputer,
     "None")

# Apply the rule
$sd = Get-ACL "AD:$OU"
$sd.AddAccessRule($ruleCreate)
Set-ACL -Path "AD:$OU" -AclObject $sd


