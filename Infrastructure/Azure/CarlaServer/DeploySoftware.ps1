param (
    [String]$Environment = ""
)



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

    Write-outpu '...Restart Service'
    Stop-Service -Name WinRM
    Set-Service -Name WinRM -StartupType Automatic
    Start-Service -Name WinRM
}

function Set-CarlaFirewall {

    Write-Output '...Carla Firewall'...
    netsh advfirewall firewall add rule name="Carla 2000" protocol=TCP dir=in localport=2000 action=allow
    netsh advfirewall firewall add rule name="Carla 2001" protocol=TCP dir=in localport=2001 action=allow
    netsh advfirewall firewall add rule name="Carla 2002" protocol=TCP dir=in localport=2002 action=allow
}

function Install-Server {

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

}
function Install-Client {

    write-output "Install Chocolatey"
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    write-output "Install Anaconda"
    choco install anaconda3 -y

}

function New-CarlaDesktopIcon{
    $SourceFileLocation = "C:\Temp\CARLA_0.9.9.3\WindowsNoEditor\CarlaUE4.exe"
    $ShortcutLocation = "C:\Users\$env:USERNAME\Desktop\CarlaUE4.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
    $Shortcut.TargetPath = $SourceFileLocation
    $Shortcut.IconLocation = "C:\Users\$env:USERNAME\Downloads\CarlaUE4.lnk"
    $Shortcut.Arguments = ""
    $Shortcut.Save()
}

function New-CarlaService {
    new-service -Name "CarlaServer" -BinaryPathName "C:\Temp\WindowsNoEditor\CarlaUE4.exe" -DisplayName "CarlaServer" -Description "CarlaServer" -StartupType "Automatic"
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
    choco install 7zip -y -force
    start-process -FilePath "C:\ProgramData\chocolatey\bin\7z.exe" -ArgumentList "x C:\Temp\398.75-tesla-desktop-winserver2016-international.exe -oC:\Temp\NvideaSetup -y" -PassThru -wait
    start-process -FilePath "C:\Temp\NvideaSetup\Setup.exe" -ArgumentList "-s" -PassThru -Wait

}

if ($Environment -match "Server") {
    Set-WINRM
    Set-CarlaFirewall
    Install-Server
}

if ($Environment -match "Client") {
    Install-Client
}

if (!($Environment)) {
    Set-WINRM
    Set-CarlaFirewall
    Install-Server
    New-CarlaDesktopIcon
    New-CarlaService
    Install-Client
    Install-Nvidea
}