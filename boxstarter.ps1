New-Item -Path 'C:\ProgramData\Boxstarter\SetupFlags\' -ItemType Directory
# $firefoxInstalled = Test-Path "C:\ProgramData\Boxstarter\SetupFlags\Firefox.txt"
# $vscodeInstalled  = Test-Path "C:\ProgramData\Boxstarter\SetupFlags\VSCode.txt"

# if (-not $firefoxInstalled) {
#     Write-Host "`n Installing Firefox..."
#     choco install firefox -y
#     New-Item -ItemType File -Path "C:\ProgramData\Boxstarter\SetupFlags\Firefox.txt" | Out-Null

#     Write-Host "`n Rebooting to continue setup..."
#     Invoke-Reboot
#   }

# if (-not $vscodeInstalled) {
#       Write-Host "`n Installing VS Code..."
#       choco install vscode -y
#       New-Item -ItemType File -Path "C:\ProgramData\Boxstarter\SetupFlags\VSCode.txt" | Out-Null
#   }

$zipUrl = "https://boxstarterlumi.blob.core.windows.net/installers/AGMCore.zip"
$packageName = "lumiagm.26.0.0.2"
$libPath = "C:\ProgramData\chocolatey\lib\$packageName"
$zipFilePath = "$libPath\AGMCore.zip"

### Install Core

# Ensure the lib folder exists
if (-not (Test-Path $libPath)) {
    New-Item -ItemType Directory -Path $libPath -Force | Out-Null
}

# Download the ZIP file
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath

# Unzip contents
Expand-Archive -LiteralPath $zipFilePath -DestinationPath $libPath -Force

# Optionally delete the ZIP after extraction
Remove-Item $zipFilePath

Write-Host "Files extracted to: $libPath"

cd $libPath

# choco pack

choco install "${packageName}.nupkg"  -s $libPath --force

Write-Host "AGM Core Installed"

Write-Host "`n Setup complete!"