
#Obtaining Student Lab Information

$LabNumber = Read-Host Enter your Lab Number
$DomainName = "adatumvs$LabNumber.virsoftlabs.com"

#Logging in to Office 365
Connect-MsolService

#Converting Faderated Domain to Standard Domain and save the temporary password to c:\password.txt file. If it is Federated Domain
If(((Get-MsolDomain -DomainName $DomainName).Authentication) -eq "Federated")
{
    Convert-MsolDomainToStandard -DomainName $DomainName –SkipUserConversion $true -PasswordFile c:\password.txt
}

#Remove ADFS Role from LON-DC1
Remove-WindowsFeature -Name ADFS-Federation

#Removing Managed Service Account created during Azure AD Connect Installation
Get-ADServiceAccount -Filter * | Remove-ADserviceAccount -confirm:$false

#Deleting GPO created for Office 365 ProPlus Installation
Get-GPO -All | Where-Object {$_.Displayname -notlike "Default*"} | Remove-GPO

#Moving LON-CL4 to the original path
Get-ADComputer -Identity LON-CL4 | Move-ADObject -targetpath "CN=Computers,DC=Adatum,DC=com"

#Deleting Adatum_Computer OU created for Office 365 ProPlus Installation
Get-ADOrganizationalUnit -Filter {Name -like "Adatum*"} | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $false
Get-ADOrganizationalUnit -Filter {Name -like "Adatum*"}  | Remove-ADOrganizationalUnit -Confirm:$false

#Disabling Directory Synchronisation
Set-MsolDirSyncEnabled -EnableDirSync $false -Force

#Changing AD User UPN Suffix to adatum.com
Get-ADUser –Filter * -Properties SamAccountName | ForEach { Set-ADUser $_ -UserPrincipalName ($_.SamAccountName + "@adatum.com" )}

#Removing UPN Suffixes from adatum.com
Get-ADForest | Set-ADForest -UPNSuffixes $null

#Deleting User and Group created for lab 4, and bringing back the original group membership 
Add-ADGroupMember -Identity Research -Members Claire, Connie, Esther
Get-ADUser -Identity Ada | Move-ADObject -TargetPath "OU=Marketing,DC=Adatum,DC=com"
Get-ADUser -Identity Vera | Move-ADObject -TargetPath "OU=Research,DC=Adatum,DC=com"
Get-ADGroup -Filter {Name -like "Project*"} | Remove-ADGroup -Confirm:$false
Remove-ADUser -Identity Perry -Confirm:$false

#Deleting DNZ Forward Lookup Zones created
Get-DNSServerZone | Where-Object {$_.Name -ne "adatum.com"} | Remove-DNSServerZone -confirm:$false
