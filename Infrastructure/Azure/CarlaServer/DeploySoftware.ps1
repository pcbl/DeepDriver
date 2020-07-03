param (
    [String]$Environment = ""
)


function Install-Choco {
    write-output "Install Chocolatey"
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
function Set-WINRM {
    Write-Output '...Activate WinRM...'
    Write-Output '...Config...'
    winrm quickconfig -q
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="8192"}'
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'

    Write-Output '...Firewall'...
    netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
    netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow

    Write-Output '...Profile and Trusted'
    Enable-PSRemoting -SkipNetworkProfileCheck -Force
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -force

    Write-output '...Restart Service'
    Stop-Service -Name WinRM
    Set-Service -Name WinRM -StartupType Automatic
    Start-Service -Name WinRM
}
function Install-Carla {

    write-output "Download Carla"
    $DestinationFolder = "C:\Temp"
    $File = "CARLA_0.9.9.4.zip"
    $URL = "https://carla-releases.s3.eu-west-3.amazonaws.com/Windows/$File"

    if (!(test-path "$DestinationFolder")) { new-item "$DestinationFolder" -itemtype Directory}

    $wc = New-Object net.webclient
    $wc.Downloadfile("$URL", "$DestinationFolder\$File")

    write-output "Extract Carla"
    $ProgressPreference = "SilentlyContinue"
    Expand-Archive -LiteralPath "$DestinationFolder\$File" -DestinationPath "$DestinationFolder"

    # write-output "Set Icon Carla"
    # $SourceFileLocation = "C:\Temp\CARLA_0.9.9.3\WindowsNoEditor\CarlaUE4.exe"
    # $ShortcutLocation = "C:\Users\azureuser\Desktop\CarlaUE4.lnk"
    # $WScriptShell = New-Object -ComObject WScript.Shell
    # $Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
    # $Shortcut.TargetPath = $SourceFileLocation
    # $Shortcut.IconLocation = "C:\Temp\WindowsNoEditor\CarlaUE4.exe"
    # $Shortcut.Arguments = ""
    # $Shortcut.Save()

    write-output "Set Service Carla"
    new-service -Name "CarlaServer" -BinaryPathName "C:\Temp\WindowsNoEditor\CarlaUE4.exe" -DisplayName "CarlaServer" -Description "CarlaServer" -StartupType "Automatic"

}
function Set-CarlaFirewall {

    Write-Output '...Carla Firewall'...
    netsh advfirewall firewall add rule name="Carla 2000" protocol=TCP dir=in localport=2000 action=allow
    netsh advfirewall firewall add rule name="Carla 2001" protocol=TCP dir=in localport=2001 action=allow
    netsh advfirewall firewall add rule name="Carla 2002" protocol=TCP dir=in localport=2002 action=allow
}
function Install-Nvidea {
    write-output "Download Nvidea"
    $DestinationFolder = "C:\Temp"
    $File = "398.75-tesla-desktop-winserver2016-international.exe"
    $URL = "https://us.download.nvidia.com/Windows/Quadro_Certified/398.75/$File"
    if (!(test-path "$DestinationFolder")) { new-item "$DestinationFolder" -itemtype Directory}
    $wc = New-Object net.webclient
    $wc.Downloadfile("$URL", "$DestinationFolder\$File")

    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    start-process -FilePath "C:\ProgramData\chocolatey\bin\choco.exe" -ArgumentList "install 7zip -y -force" -PassThru -wait -NoNewWindow
    start-process -FilePath "C:\ProgramData\chocolatey\bin\7z.exe" -ArgumentList "x C:\Temp\398.75-tesla-desktop-winserver2016-international.exe -oC:\Temp\NvideaSetup -y" -PassThru -Wait -NoNewWindow
    start-process -FilePath "C:\Temp\NvideaSetup\Setup.exe" -ArgumentList "-s" -PassThru -Wait -NoNewWindow
}
function Install-VCRedist {
    start-process -FilePath C:\ProgramData\chocolatey\bin\choco.exe -ArgumentList "install vcredist140 -y -force" -PassThru -wait -NoNewWindow
}
function Install-directX {

    write-output "Download DirectX"
    $DestinationFolder = "C:\Temp"
    $File = "directx_dec2006_redist.exe"
    $URL = "https://download.microsoft.com/download/8/c/9/8c968ecc-8402-49f3-aacb-dc4c5d230a9a/$file"

    if (!(test-path "$DestinationFolder")) { new-item "$DestinationFolder" -itemtype Directory}

    $wc = New-Object net.webclient
    $wc.Downloadfile("$URL", "$DestinationFolder\$File")

    write-output "Install DirectX"
    $ProgressPreference = "SilentlyContinue"
    start-process -FilePath "C:\ProgramData\chocolatey\bin\7z.exe" -ArgumentList "x C:\Temp\directx_dec2006_redist.exe -oC:\Temp\directx -y" -PassThru -Wait -NoNewWindow
    start-process -FilePath "C:\Temp\directx\DXSETUP.exe" -ArgumentList "/silent" -PassThru -Wait -NoNewWindow    
}
function Install-Anaconda {

    write-output "Install Anaconda"
    start-process -FilePath C:\ProgramData\chocolatey\bin\choco.exe -ArgumentList "install anaconda3 -y" -PassThru -wait -NoNewWindow

}

Start-Transcript "C:\Temp\CarlaServer-DeploySoftware.log"
if ($Environment -match "Server") {
    Install-Choco
    Set-WINRM
    Install-Carla
    Set-CarlaFirewall
    Install-Nvidea
    Install-VCRedist
    Install-directX
}

if ($Environment -match "Client") {
    Install-Anaconda
}

if (!($Environment)) {
    Install-Choco
    Set-WINRM
    Install-Carla
    Set-CarlaFirewall
    Install-Nvidea
    Install-VCRedist
    Install-directX

    Install-Anaconda
}