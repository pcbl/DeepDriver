# Download Carla
$DestinationFolder = "C:\Temp"
$File = "CARLA_0.9.9.4.zip"
$URL = "https://carla-releases.s3.eu-west-3.amazonaws.com/Windows/$File"

if (!(test-path "$DestinationFolder")) { new-item "$DestinationFolder" -itemtype Directory}

$wc = New-Object net.webclient
$wc.Downloadfile("$URL", "$DestinationFolder\$File")

# Extract Carla
Expand-Archive -LiteralPath "$DestinationFolder\$File" -DestinationPath "$DestinationFolder"

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Anaconda
choco install anaconda3 -y