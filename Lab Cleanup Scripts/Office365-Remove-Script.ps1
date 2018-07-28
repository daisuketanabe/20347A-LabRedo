#Obtaining Student Lab Information

$LabNumber = Read-Host Enter your Lab Number
$DomainName = "adatumvs$LabNumber.virsoftlabs.com"
$credential = Get-Credential

#Logging in to Office 365
Connect-MsolService -Credential $credential

#Connectng to Exchnage Online PowerShell
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
Import-PSSession $ExchangeSession -DisableNameChecking

#Connecing to Office 365 Security and Compliance Centre
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $credential -Authentication Basic -AllowRedirection
Import-PSSession $Session

$SfbSession = New-CsOnlineSession –Credential $credential
Import-PSSession $SfbSession

#Remove All Users expect for Holly
Get-Msoluser | Where-Object {$_.DisplayName -notLike "Holly*"} | Remove-MsolUser –Force
Get-MsolUser -ReturnDeletedUsers | Remove-MsolUser -RemoveFromRecycleBin -Force

#Obtaining the Initial onmicrosoft.com Domain name
$DefaultDomain = (Get-MsolDomain | Where-Object {$_.IsInitial -eq $true}).name

#Change Holly's UPN to onmicrosoft.com Domain
$DefaultHolly = "Holly@$DefaultDomain"
Set-MsolUserPrincipalName -ObjectId (Get-Msoluser | Where-Object {$_.DisplayName -Like "Holly*"}).ObjectID -NewUserPrincipalName $DefaultHolly

#Removing All Office 365 Security Groups
Get-MsolGroup | Remove-MsolGroup -Force

#Removing all additional Email Addresses from Holly
$HollyMB = get-mailbox -Identity Holly
foreach ($HollyEmailAddress in $HollyMB.EmailAddresses)
{
    if ($HollyEmailAddress -clike "smtp*")
    {
        $HollyMB.EmailAddresses.remove("$HollyEmailAddress")
        Set-Mailbox -Identity Holly -EmailAddresses $HollyMB.EmailAddresses
    }
}


### Reverting Lab 11 #################################
# * Sharepoint IRM Setting must be manually updated. #
######################################################

$DlpCompliancePolicies = Get-DlpCompliancePolicy | Where-Object {$_.Mode -ne "PendingDeletion"}

foreach ($DlpCompliancePolicy in $DlpCompliancePolicies)
{
    Remove-DlpCompliancePolicy -Identity $DlpCompliancePolicy.Identity -Confirm:$false
}

$RetentionCompliancePolicies = Get-RetentionCompliancePolicy

foreach ($RetentionCompliancePolicy in $RetentionCompliancePolicies)
{
    Remove-RetentionCompliancePolicy -Identity $RetentionCompliancePolicy.Identity -Confirm:$false

}

$RetentionPolicyTags = Get-RetentionPolicyTag | Sort-Object WhenCreated

$i = 1

Foreach ($RetentionPolicyTag in $RetentionPolicyTags)
{
    If ($i -gt 13)
    {
        Remove-RetentionPolicyTag $RetentionPolicyTag.Identity -Confirm:$false
    }
    $i++
}

$RetentionPolicies = Get-RetentionPolicy | Where-Object {$_.IsDefault -eq $False -and $_.IsDefaultArbitrationMailbox -eq $False}

foreach ($RetentionPolicy in $RetentionPolicies)
{
    Remove-RetentionPolicy -Identity $RetentionPolicy.Identity -Confirm:$false
}

#Disabling Auditing
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $false

#Disabling RMS from Exchange Online
Set-IRMConfiguration -InternalLicensingEnabled $false
Set-IRMConfiguration -RMSOnlineKeySharingLocation $null
Get-RMSTrustedPublishingDomain | Remove-RMSTrustedPublishingDomain -Confirm:$false -Force

#Disabling ADRMS
Connect-AadrmService -Credential $credential

Disable-Aadrm

####Reverting Lab 10 #############################
# * Yammer Settings must be manually reverted    #
##################################################

Get-UnifiedGroup | Remove-UnifiedGroup -Confirm:$false

### Reverting Lab 09 #############################
#Site Collection Storage Management
#Use Yammer.com service.
#Apps for Office from the Store

#Connectng to SharePoint Online PowerShell
$OrgName = $DefaultDomain.Replace('.onmicrosoft.com','')
Connect-SPOService -Url https://$OrgName-admin.sharepoint.com -Credential $credential

Set-SPOTenant -SharingCapability ExternalUserAndGuestSharing

get-sposite | Where-Object {$_.Owner -ne ""} | Remove-SPOSite -Confirm:$false
Get-SPODeletedSite | Remove-SPODeletedSite -Confirm:$false

### Reverting Lab 08 #############################

Set-CsMeetingConfiguration -HelpURL $Null -CustomFooterText $Null

foreach ($BlockedDomain in (get-CsTenantFederationConfiguration).BlockedDomains)
{
    Set-CsTenantFederationConfiguration -BlockedDomains @{remove=$BlockedDomain}
}

Set-CsTenantFederationConfiguration –AllowFederatedUsers $true

Set-CsTenantFederationConfiguration –AllowPublicUsers $true

Set-CsPushNotificationConfiguration -EnableApplePushNotification $true

Set-CsPrivacyConfiguration -EnablePrivacyMode $false

Set-CsBroadcastMeetingConfiguration –EnableBroadcastMeeting $false


### Reverting Lab 07B ###########################

Get-MobileDeviceMailboxPolicy | Where-Object {$_.IsDefault -ne $True} | Remove-MobileDeviceMailboxPolicy -Confirm:$false
Get-MobileDeviceMailboxPolicy | Set-MobileDeviceMailboxPolicy -PasswordEnabled $false -MinPasswordLength $null

$DefaultOWAPolicy = Get-OwaMailboxPolicy | Where-Object {$_.IsDefault -eq $True}
Get-CASMailbox | Set-CASMailbox -OwaMailboxPolicy $DefaultOWAPolicy.Name
Get-OwaMailboxPolicy | Where-Object {$_.IsDefault -ne $True} | Remove-OwaMailboxPolicy -Confirm:$false

Get-HostedContentFilterPolicy | Where-Object {$_.IsDefault -ne $True} | Remove-HostedContentFilterPolicy -Confirm:$false

Get-HostedContentFilterPolicy | Set-HostedContentFilterPolicy -HighConfidenceSpamAction MoveTojmf

$IPBlockList = (Get-HostedConnectionFilterPolicy).IPBlockList

Get-HostedConnectionFilterPolicy | Set-HostedConnectionFilterPolicy -EnableSafeList $false

foreach ($IPblock in $IPBlockList)
{
    Get-HostedConnectionFilterPolicy | Set-HostedConnectionFilterPolicy -IPBlockList @{Remove=$IPblock}
}

Get-MalwareFilterPolicy | Where-Object {$_.IsDefault -ne $true} | Remove-MalwareFilterPolicy -Confirm:$false

Get-MalwareFilterPolicy | Set-MalwareFilterPolicy -EnableInternalSenderNotifications $false -EnableExternalSenderAdminNotifications $false -EnableInternalSenderAdminNotifications $false -InternalSenderAdminAddress "<>" -ExternalSenderAdminAddress "<>"

### Reverting Lab 07A ###########################

Get-JournalRule | Remove-JournalRule -Confirm:$false

Set-TransportConfig -JournalingReportNdrTo "<>"

Get-TransportRule | Remove-TransportRule -Confirm:$false

Get-InboundConnector | Remove-InboundConnector -Confirm:$false

Get-OutboundConnector | Remove-OutboundConnector -Confirm:$false

### Reverting Lab 06 ###########################

$DefaultUserRole = Get-RoleAssignmentPolicy | Sort-Object WhenCreated | Select-Object -First 1

Set-RoleAssignmentPolicy $DefaultUserRole.Name -IsDefault -Confirm:$false

$UserRoles = Get-RoleAssignmentPolicy | Where-Object {$_.IsDefault -ne $True} 

foreach ($UserRole in $UserRoles)
{
    Get-ManagementRoleAssignment | Where-Object {$_.RoleAssigneename -eq $UserRole.Identity} | Remove-ManagementRoleAssignment -Confirm:$false
    Remove-RoleAssignmentPolicy -Identity $UserRole.Identity -Confirm:$false
}

$RoleGroups = Get-RoleGroup
foreach ($RoleGroup in $RoleGroups)
{
    $ManagedBys = $RoleGroup.ManagedBy | Measure-Object

    if ($ManagedBys.count -ne 1)
    {
        Remove-RoleGroup -Identity $RoleGroup.Identity -Confirm:$false
    }
}

Get-MailContact | Remove-MailContact -Confirm:$false

Get-Mailbox -RecipientTypeDetails EquipmentMailbox | Remove-Mailbox -Confirm:$false

Get-Mailbox -RecipientTypeDetails RoomMailbox | Remove-Mailbox -Confirm:$false

Get-DistributionGroup | Remove-DistributionGroup -Confirm:$false

### Reverting Lab 05 ###########################
# Covered by LON-DC1-Remove-Script.ps1 Script
# Run LON-CL1-Remove-Script.ps1 Script
# Uninstall Office 365 ProPlus from LON-CL3
# Uninstall Office 365 ProPlus from LON-CL4
# Check Office software download settings

### Reverting Lab 04 ###########################
# Covered by LON-DC1-Remove-Script.ps1 Script

### Reverting Lab 03 ###########################
# Covered by LON-DC1-Remove-Script.ps1 Script

### Reverting Lab 02 ###########################

Set-MsolPasswordPolicy -DomainName $DefaultDomain -NotificationDays 14 -ValidityPeriod 730

#Removing All custom Domains
Get-MsolDomain | Where-Object {$_.IsInitial -eq $true} | Set-MsolDomain –IsDefault
$RemovingDomains = Get-MsolDomain | Where-Object {$_.IsInitial -ne $true}

foreach ($RemovingDomain in $RemovingDomains)
{
    Remove-MsolDomain -DomainName $RemovingDomain.Name -Force
} 


