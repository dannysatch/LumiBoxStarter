New-Item -Path 'C:\ProgramData\Boxstarter\SetupFlags\' -ItemType Directory -Force | Out-Null

$workDir = "C:\LumiSetup\" 
$zipUrl = "https://boxstarterlumi.blob.core.windows.net/installers/boxstarter.zip"
$zipFilePath = Join-Path $workDir "boxstarter.zip"

### Install Core

# Ensure the lib folder exists
if (-not (Test-Path $libPath)) {
    New-Item -Path $workDir -ItemType Directory -Force | Out-Null
}

# Download the ZIP file
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath

# Unzip contents
Expand-Archive -LiteralPath $zipFilePath -DestinationPath $workDir -Force

# Optionally delete the ZIP after extraction
Remove-Item $zipFilePath

Write-Host "Files extracted to: $workDir"

cd $workDir

$ErrorActionPreference = 'Stop'

