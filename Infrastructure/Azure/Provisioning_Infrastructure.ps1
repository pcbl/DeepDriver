write-output "Install Chocolatay..."
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

write-output "Install azure-cli..."
choco install azure-cli -y

write-output "authenticate on Azure..."
az login
Pause

write-output "Initialize Terraform..."
Set-location .\CarlaServer
terraform init
Pause

write-output "Plan Terraform..."
Set-location .\CarlaServer
Terraform plan
Pause

write-output "Apply Terraform..."
Set-location .\CarlaServer
terraform apply -auto-approve
Pause


