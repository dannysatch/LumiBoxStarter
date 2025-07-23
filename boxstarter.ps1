
# # Install Google Chrome
# choco install firefox -y

# # Reboot the system
# Invoke-Reboot

# # After reboot, install VS Code
# choco install vscode -y


$firefoxInstalled = Test-Path "C:\ProgramData\Boxstarter\SetupFlags\Firefox.txt"
$vscodeInstalled  = Test-Path "C:\ProgramData\Boxstarter\SetupFlags\VSCode.txt"

if (-not $firefoxInstalled) {
    Write-Host "`n Installing Firefox..."
    choco install firefox -y
    New-Item -ItemType File -Path "C:\ProgramData\Boxstarter\SetupFlags\Firefox.txt" | Out-Null

    Write-Host "`n Rebooting to continue setup..."
    Invoke-Reboot
  }

if (-not $vscodeInstalled) {
      Write-Host "`n Installing VS Code..."
      choco install vscode -y
      New-Item -ItemType File -Path "C:\ProgramData\Boxstarter\SetupFlags\VSCode.txt" | Out-Null
  }

    Write-Host "`n Setup complete!"
