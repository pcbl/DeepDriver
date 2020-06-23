write-output "Install Chocolatay..."
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

write-output "Install azure-cli..."
choco install azure-cli -y

write-output "authenticate on Azure..."
az login

Set-location .\CarlaServer

write-output "Initialize Terraform..."
terraform init
Pause

write-output "Plan Terraform..."
Terraform plan
Pause

write-output "Apply Terraform..."
terraform apply -auto-approve
Pause


