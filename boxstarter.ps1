New-Item -Path 'C:\ProgramData\Boxstarter\SetupFlags\' -ItemType Directory -Force | Out-Null

$workDir = "C:\LumiSetup\" 
$zipUrl = "https://boxstarterlumi.blob.core.windows.net/installers/boxstarter.zip"
$zipFilePath = Join-Path $workDir "boxstarter.zip"

### Install Core

# Ensure the lib folder exists
if (-not (Test-Path $workDir)) {
    New-Item -Path $workDir -ItemType Directory -Force | Out-Null
}

# Download the ZIP file
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath

# Unzip contents
Expand-Archive -LiteralPath $zipFilePath -DestinationPath $workDir -Force

# Optionally delete the ZIP after extraction
Remove-Item $zipFilePath

Write-Host "Files extracted to: $workDir"

# Script 0 (Set ExecutionPolicy)
Start-Process "cmd.exe" -ArgumentList "/c `"$workDir\0_AllowPowershell (right-click and run as administrator).cmd`"" -Verb RunAs -Wait

# Script 2
Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\2_LumiComputerSetup-AfterInstallingOS.ps1`"" -Verb RunAs -Wait

# Script 3
Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\3_LumiComputerSetup-AfterInstallingOS.ps1`"" -Verb RunAs -Wait

$ErrorActionPreference = 'Stop'

