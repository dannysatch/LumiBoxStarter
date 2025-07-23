Import-Module "$env:ProgramData\Boxstarter\Boxstarter.Chocolatey\Boxstarter.Chocolatey.psd1"

# Install Google Chrome
choco install googlechrome -y

# Reboot the system
Restart-ComputerAndContinue

# After reboot, install VS Code
choco install vscode -y
