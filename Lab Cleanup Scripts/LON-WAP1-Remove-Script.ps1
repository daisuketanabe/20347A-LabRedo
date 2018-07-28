Remove-Item C:\Windows\system32\drivers\etc\hosts.tmp -Confirm:$false

foreach($line in Get-Content C:\Windows\system32\drivers\etc\hosts)
{
    if($line -match "#")
    {
        Add-Content -PassThru C:\Windows\system32\drivers\etc\hosts.tmp -Value $line
    }
}

Remove-Item C:\Windows\system32\drivers\etc\hosts.bak -Confirm:$false

Rename-Item -Path C:\Windows\system32\drivers\etc\hosts -NewName hosts.bak

Rename-Item -Path C:\Windows\system32\drivers\etc\hosts.tmp -NewName hosts 

Remove-WindowsFeature -Name Web-Application-Proxy
