
function Set-OSConfig {

Write-Output '...Set Timezone...'
Set-TimeZone -name "W. Europe Standard Time"
Write-Output '...Sync Time...'
w32tm /resync | Out-Null
Write-Output '...set local System language...'
set-WinSystemLocale de-DE   
Write-Output '...set Keyboardsprache...'
Set-WinUserLanguageList -LanguageList DE-DE -Force

} 

function Install-Choco {
    write-output "...Install Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

function Set-WINRM {
    Write-Output '...Activate WinRM...'
    Write-Output '...Config...'
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
    
    winrm quickconfig -q
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="8192"}'
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'

    Write-Output '...Firewall...'
    netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
    netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow

    Write-Output '...Profile and Trusted...'
    Enable-PSRemoting -SkipNetworkProfileCheck -Force
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -force

    Write-output '...Restart Service...'
    Stop-Service -Name WinRM
    Set-Service -Name WinRM -StartupType Automatic
    Start-Service -Name WinRM
}

function Install-7zip {
    write-output "...Install 7zip..."
    start-process -FilePath "C:\ProgramData\chocolatey\bin\choco.exe" -ArgumentList "install 7zip -y -force" -wait -NoNewWindow 
}

function Set-AutoLogon {
    Write-Output 'activate Auto Logon'
    New-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "DefaultUsername" -value "azureuser" -Force
    New-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "DefaultPassword" -value "xotqgp34XtL7DwM2MtcC" -Force
    New-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "AutoAdminLogon" -value "1" -Force
}

Start-Transcript "C:\Temp\CarlaServer-DeployPostConfig.log"
$global:ProgressPreference = 'SilentlyContinue'

Set-OSConfig
Install-Choco
Set-WINRM
Install-7zip
Set-AutoLogon

write-output "...Start Deploy Software..."
start-process "powershell.exe" -ArgumentList "-ExecutionPolicy bypass -file .\DeploySoftware.ps1" -wait -NoNewWindow -ErrorAction Ignore

Stop-Transcript

write-output "Restart Computer"
Restart-Computer