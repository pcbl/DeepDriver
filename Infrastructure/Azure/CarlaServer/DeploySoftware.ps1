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

    # write-output "Set Icon Carla"
    # $SourceFileLocation = "C:\Temp\CARLA_0.9.9.3\WindowsNoEditor\CarlaUE4.exe"
    # $ShortcutLocation = "C:\Users\azureuser\Desktop\CarlaUE4.lnk"
    # $WScriptShell = New-Object -ComObject WScript.Shell
    # $Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
    # $Shortcut.TargetPath = $SourceFileLocation
    # $Shortcut.IconLocation = "C:\Temp\WindowsNoEditor\CarlaUE4.exe"
    # $Shortcut.Arguments = ""
    # $Shortcut.Save()

    write-output "Set Service Carla..."
    new-service -Name "CarlaServer" -BinaryPathName "C:\Temp\WindowsNoEditor\CarlaUE4.exe" -DisplayName "CarlaServer" -Description "CarlaServer" -StartupType "Automatic"

    Write-Output '...Set Carla Firewall'...
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

# function SMI {
#     # C:\Program Files\NVIDIA Corporation\NVSMI> .\nvidia-smi.exe
#     # .\nvidia-smi -g B794:00:00.0 -dm 0
# }

$global:ProgressPreference = 'SilentlyContinue'

Install-Carla
Install-Nvidea
Install-VCRedist
Install-directX
Install-Anaconda