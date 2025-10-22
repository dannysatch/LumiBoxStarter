$workDir = "C:\LumiSetup\" 
$zipUrl = "https://boxstarterlumi.blob.core.windows.net/installers/boxstarter.zip"
$zipFilePath = Join-Path $workDir "boxstarter.zip"

$DownloadFlag = Join-Path $workDir "Download.flag"
$Script0Flag = Join-Path $workDir "Script0.flag"
$Script2Flag = Join-Path $workDir "Script2.flag"
$Script3Flag = Join-Path $workDir "Script3.flag"

### Install Core

# Ensure the lib folder exists
if (-not (Test-Path $workDir)) {
    New-Item -Path $workDir -ItemType Directory -Force | Out-Null
}

# Download the ZIP file
if (-not (Test-Path $DownloadFlag)) {
    
    # Download the ZIP file
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath

    # Unzip contents
    Expand-Archive -LiteralPath $zipFilePath -DestinationPath $workDir -Force

    # Optionally delete the ZIP after extraction
    Remove-Item $zipFilePath

    Write-Host "Files extracted to: $workDir"

    New-Item -ItemType File -Path "$workDir\Download.flag" | Out-Null

    Write-Host "`n Rebooting to continue setup..."

}


# Script 0 (Set ExecutionPolicy)
if (-not (Test-Path $Script0Flag)) {
    
    Start-Process "cmd.exe" -ArgumentList "/c `"$workDir\0_AllowPowershell (right-click and run as administrator).cmd`"" -Verb RunAs -Wait

    New-Item -ItemType File -Path "$workDir\Script0.flag" | Out-Null

    Write-Host "`n Rebooting to continue setup..."
}


# Script 2
 if (-not (Test-Path $Script2Flag)) {
    
    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\2_LumiComputerSetup-AfterInstallingOS.ps1`"" -Verb RunAs -Wait

    New-Item -ItemType File -Path "$workDir\Script2.flag" | Out-Null

    Write-Host "`n Rebooting to continue setup..."

    Invoke-Reboot

}


# Script 3
if (-not (Test-Path $Script3Flag)) {
    
    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\3_LumiComputerSetup-AfterInstallingOS.ps1`"" -Verb RunAs -Wait
    New-Item -ItemType File -Path "$workDir\Script3.flag" | Out-Null

    Write-Host "`n Rebooting to continue setup..."

    Invoke-Reboot

}


# Install SQL Server
choco install sql-server-express

# Install SSMS
choco install sql-server-management-studio


$ErrorActionPreference = 'Stop'

