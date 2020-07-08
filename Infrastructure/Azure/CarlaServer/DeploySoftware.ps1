param (
    [String]$Env = ""
)

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

}

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

Function Add-TaskScheduler ($Task) {

    $action = New-ScheduledTaskAction -Execute 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Argument "-command `"Start-Process C:\Temp\WindowsNoEditor\CarlaUE4.exe -argumentlist `'-carla-settings=CarlaUE4\Config\GFT.ini'`""
    $Taskname = "Carla"
    $trigger1 = New-ScheduledTaskTrigger -AtLogOn
    $User = "azureuser"
    $Principal = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Highest
    Register-ScheduledTask -Action $action -Trigger @($trigger1) -TaskName "$Taskname" -Principal $Principal

}

Start-Transcript "C:\Temp\CarlaServer-DeploySoftware.log"
$global:ProgressPreference = 'SilentlyContinue'

if ($Env -match "Client") {
    choco install anaconda3 -y
    pip install --user pygame numpy

} else {

    Install-Carla
    Install-Nvidea
    Install-VCRedist
    Install-directX
    Set-SMI
    Add-TaskScheduler

}

Stop-Transcript

write-output "Restart Computer"
Restart-Computer
