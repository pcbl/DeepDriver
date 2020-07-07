function Install-Carla {

    write-output "Download Carla..."
    $DestinationFolder = "C:\Temp"
    $File = "CARLA_0.9.9.4.zip"
    $URL = "https://carla-releases.s3.eu-west-3.amazonaws.com/Windows/$File"

    if (!(test-path "$DestinationFolder")) { new-item "$DestinationFolder" -itemtype Directory}

    $wc = New-Object net.webclient
    $wc.Downloadfile("$URL", "$DestinationFolder\$File")

    write-output "Extract Carla..."
    $ProgressPreference = "SilentlyContinue"
    Expand-Archive -LiteralPath "$DestinationFolder\$File" -DestinationPath "$DestinationFolder"

    # write-output "Set Service Carla..."
    # new-service -Name "CarlaServer" -BinaryPathName "C:\Temp\WindowsNoEditor\CarlaUE4.exe" -DisplayName "CarlaServer" -Description "CarlaServer" -StartupType "Automatic"

    Write-Output "...Set Carla Firewall..."
    netsh advfirewall firewall add rule name="Carla 2000" protocol=TCP dir=in localport=2000 action=allow
    netsh advfirewall firewall add rule name="Carla 2001" protocol=TCP dir=in localport=2001 action=allow
    netsh advfirewall firewall add rule name="Carla 2002" protocol=TCP dir=in localport=2002 action=allow

    Write-Output "...Copy Ini file..."
    Copy-item .\GFT.ini "C:\Temp\WindowsNoEditor\CarlaUE4\Config\GFT.ini"

    Write-Output "...Copy StartupFile..."
    #move-item .\CarlaUE4.download CarlaUE4.lnk
    if (!(test-path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup")) {New-item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -itemtype Directory }
    Copy-item ".\CarlaUE4.lnk" "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\CarlaUE4.lnk"

    if (!(test-path "C:\Users\azureuser.DeepDriverVM\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup")) {New-item "C:\Users\azureuser.DeepDriverVM\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -itemtype Directory }
    Copy-item ".\CarlaUE4.lnk" "C:\Users\azureuser.DeepDriverVM\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\CarlaUE4.lnk"

    if (!(test-path "C:\Users\azureuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup")) {New-item "C:\Users\azureuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -itemtype Directory }
    Copy-item ".\CarlaUE4.lnk" "C:\Users\azureuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\CarlaUE4.lnk"

    if (!(test-path "C:\Users\azureuser.DeepDriverVM.000\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup")) {New-item "C:\Users\azureuser.DeepDriverVM.000\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -itemtype Directory }
    Copy-item ".\CarlaUE4.lnk" "C:\Users\azureuser.DeepDriverVM.000\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\CarlaUE4.lnk"
    
    if (!(test-path "C:\Users\azureuser.DeepDriverVM.001\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup")) {New-item "C:\Users\azureuser.DeepDriverVM.000\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -itemtype Directory }
    Copy-item ".\CarlaUE4.lnk" "C:\Users\azureuser.DeepDriverVM.000\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\CarlaUE4.lnk"

    if (!(test-path "C:\Users\azureuser.DeepDriverVM.002\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup")) {New-item "C:\Users\azureuser.DeepDriverVM.000\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -itemtype Directory }
    Copy-item ".\CarlaUE4.lnk" "C:\Users\azureuser.DeepDriverVM.000\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\CarlaUE4.lnk"

    if (!(test-path "C:\Users\azureuser.DeepDriverVM.003\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup")) {New-item "C:\Users\azureuser.DeepDriverVM.000\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -itemtype Directory }
    Copy-item ".\CarlaUE4.lnk" "C:\Users\azureuser.DeepDriverVM.000\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\CarlaUE4.lnk"
}

# Function Set-Shortcut($RunPath, $Arguments, $ShortcutName, $ShortcutLocation){

#     write-output "Copy Icon Carla to StartUp"
#     $WScriptShell = New-Object -ComObject WScript.Shell
#     $Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation + $ShortcutName + '.lnk')
#     $Shortcut.Targetpath = -join($RunPath,"\CarlaUE4.exe")
#     $Shortcut.Arguments = [string]$Arguments
#     $Shortcut.WorkingDirectory = $RunPath
#     $Shortcut.IconLocation = -join($RunPath,"\CarlaUE4.exe",", 0")
#     $Shortcut.Save()

#     Write-Host "`nShortcut created at "$ShortcutLocation$ShortcutName'.lnk'
# }

function Install-Nvidea {
    write-output "Download Nvidea"
    $DestinationFolder = "C:\Temp"
    $File = "398.75-tesla-desktop-winserver2016-international.exe"
    $URL = "https://us.download.nvidia.com/Windows/Quadro_Certified/398.75/$File"
    if (!(test-path "$DestinationFolder")) { new-item "$DestinationFolder" -itemtype Directory}
    $wc = New-Object net.webclient
    $wc.Downloadfile("$URL", "$DestinationFolder\$File")

    7z.exe x C:\Temp\398.75-tesla-desktop-winserver2016-international.exe -oC:\Temp\NvideaSetup -y
    start-process -FilePath "C:\Temp\NvideaSetup\Setup.exe" -ArgumentList "-s" -PassThru -Wait -NoNewWindow 
}

function Install-VCRedist {
    choco install vcredist140 -y -force
}

function Install-directX {
    write-output "Download DirectX"
    $DestinationFolder = "C:\Temp"
    $File = "directx_Jun2010_redist.exe"
    $URL = "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/$file"

    if (!(test-path "$DestinationFolder")) { new-item "$DestinationFolder" -itemtype Directory}

    $wc = New-Object net.webclient
    $wc.Downloadfile("$URL", "$DestinationFolder\$File")

    write-output "Install DirectX"
    $ProgressPreference = "SilentlyContinue"
    7z x C:\Temp\$File -oC:\Temp\directx -y
    start-process -FilePath "C:\Temp\directx\DXSETUP.exe" -ArgumentList "/silent" -PassThru -Wait -NoNewWindow     
}

function Install-Anaconda {
    write-output "Install Anaconda"
    choco install anaconda3 -y
}

function Set-SMI {
    write-output "Set SMI"
     Set-Location "C:\Progra~1\NVIDIA Corporation\NVSMI"
     .\nvidia-smi.exe -g 00000001:00:00.0 -dm 0
}

Start-Transcript "C:\Temp\CarlaServer-DeploySoftware.log"
$global:ProgressPreference = 'SilentlyContinue'

Install-Carla
Install-Nvidea
Install-VCRedist
Install-directX
Set-SMI

# $DefaultFileName = "C:\Temp\WindowsNoEditor\CarlaUE4.exe"
# $Runapppath = "C:\Temp\WindowsNoEditor"

# Set-Shortcut $Runapppath $DefaultFileName "CarlaUE4ShortCut" "C:\Users\azureuser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\"

# Install-Anaconda
Stop-Transcript


write-output "Restart Computer"
Restart-Computer
