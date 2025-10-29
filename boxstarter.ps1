$workDir = "C:\LumiSetup\" 
$zipUrl = "https://boxstarterlumi.blob.core.windows.net/installers/boxstarter.zip"
$zipFilePath = Join-Path $workDir "boxstarter.zip"

$DownloadFlag = Join-Path $workDir "Download.flag"
$Script0Flag = Join-Path $workDir "Script0.flag"
$Script1Flag = Join-Path $workDir "Script1.flag"
$Script2Flag = Join-Path $workDir "Script2.flag"
$Script3Flag = Join-Path $workDir "Script3.flag"
$SQLFlag =  Join-Path $workDir "SQL.flag"
$ConfigFlag = Join-Path $workDir "config.flag"


## Download Set Up Files

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

}

## Run Lumi Set Up Scripts

# Script 0 (Set ExecutionPolicy)
if (-not (Test-Path $Script0Flag)) {
    
    Start-Process "cmd.exe" -ArgumentList "/c `"$workDir\0_AllowPowershell (right-click and run as administrator).cmd`"" -Verb RunAs -Wait

    New-Item -ItemType File -Path "$workDir\Script0.flag" | Out-Null

}

# Config
 if (-not (Test-Path $ConfigFlag)) {
    
    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\configStart.ps1`"" -Verb RunAs -Wait

    New-Item -ItemType File -Path "$workDir\config.flag" | Out-Null

    $configJSON = Get-Content -Path "$workDir\UserSelections.json" -Raw | ConvertFrom-Json

    Write-Host "`n Rebooting to continue setup..."

    Invoke-Reboot

}

# Script 2
 if (-not (Test-Path $Script1Flag)) {
    
    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\1_LumiComputerSetup-AfterInstallingOS.ps1`"" -Verb RunAs -Wait

    New-Item -ItemType File -Path "$workDir\Script1.flag" | Out-Null

    Write-Host "`n Rebooting to continue setup..."

    Invoke-Reboot

}

# SQL Setup
if (-not (Test-Path $SQLFlag)) {
    
    # Install SQL Server
    choco install sql-server-express

    # Install SSMS
    choco install sql-server-management-studio
    
    New-Item -ItemType File -Path "$workDir\SQL.flag" | Out-Null

    Write-Host "`n Rebooting to continue setup..."

    Invoke-Reboot

}

# Script 2
if (-not (Test-Path $Script2Flag)) {
    
    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\2_LumiComputerSetup-AfterInstallingSQL.ps1`"" -Verb RunAs -Wait
    New-Item -ItemType File -Path "$workDir\Script2.flag" | Out-Null

}


# Office Install
if (-not (Test-Path $OfficeFlag)) {
    
    # Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\5_LumiComputerSetup-InstallOffice.ps1`"" -Verb RunAs -Wait
    choco install office365business --params "/configpath:$workDir\Resources\MSOfficeInstallation\configuration.xml"
    New-Item -ItemType File -Path "$workDir\Office.flag" | Out-Null

}

# # Run Windows Updates
# Install-WindowsUpdate -AcceptEula

# Script 3
if (-not (Test-Path $Script3Flag)) {
    
    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\3_LumiComputerSetup-FinalSteps.ps1`"" -Verb RunAs -Wait
    New-Item -ItemType File -Path "$workDir\Script3.flag" | Out-Null

}


## Install Lumi Software

$selectedApps = $configJSON.SelectedApplications


# 1) IML Communicator Hub Service Installer v1.38.0.0
if ($selectedApps -contains 1) {
    Write-Host "Installing: IML Communicator Hub Service Installer v1.38.0.0..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\IML Communicator Hub Service Installer v1.38.0.0.exe" -ArgumentList "/S" -PassThru
}

# 2) IML Connector System Installer v2.50.0.0
if ($selectedApps -contains 2) {
    Write-Host "Installing: IML Connector System Installer v2.50.0.0..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\IML Connector System Installer v2.50.0.0.exe" -ArgumentList "/S" -PassThru
}

# 3) Lumi AGM Installer v27.0.0.1 (AGM Core Install)
if ($selectedApps -contains 3) {
    Write-Host "Installing: Lumi AGM Installer v27.0.0.1..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\Lumi AGM Installer v27.0.0.1.exe" -ArgumentList "/S" -PassThru
}

# 4) Lumi AGM Reg and Vote Installer v3.8.0.1
if ($selectedApps -contains 4) {
    Write-Host "Installing: Lumi AGM Reg and Vote Installer v3.8.0.1..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\Lumi AGM Reg and Vote Installer v3.8.0.1.exe" -ArgumentList "/S" -PassThru
}

# 5) Lumi AGM Studio Installer v27.0.0.0
if ($selectedApps -contains 5) {
    Write-Host "Installing: Lumi AGM Studio Installer v27.0.0.0..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\Lumi AGM Studio Installer v27.0.0.0.exe" -ArgumentList "/S" -PassThru
}

# 6) Lumi AGM Web Apps Installer v27.0.0.0
if ($selectedApps -contains 6) {
    Write-Host "Installing: Lumi AGM Web Apps Installer v27.0.0.0..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\Lumi AGM Web Apps Installer v27.0.0.0.exe" -ArgumentList "/S" -PassThru
}

# 7) Lumi Audience Display Installer v2.48.0.0
if ($selectedApps -contains 7) {
    Write-Host "Installing: Lumi Audience Display Installer v2.48.0.0..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Audience Display Installer v2.48.0.0.exe" -ArgumentList "/S" -PassThru
}

# 8) Lumi Kiosk Browser Installer v27.0.0.2
if ($selectedApps -contains 8) {
    Write-Host "Installing: Lumi Kiosk Browser Installer v27.0.0.2..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Kiosk Browser Installer v27.0.0.2.exe" -ArgumentList "/S" -PassThru
}

# 9) Lumi Live DataBase Backup Installer v2.50.0.0
if ($selectedApps -contains 9) {
    Write-Host "Installing: Lumi Live DataBase Backup Installer v2.50.0.0..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Live DataBase Backup Installer v2.50.0.0.exe" -ArgumentList "/S" -PassThru
}

# 10) Lumi Magma Hub Service Installer v1.4.0.0
if ($selectedApps -contains 10) {
    Write-Host "Installing: Lumi Magma Hub Service Installer v1.4.0.0..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Magma Hub Service Installer v1.4.0.0.exe" -ArgumentList "/S" -PassThru
}

# 11) Lumi ProjectorPowerPoint Installer v2.22.0.0
if ($selectedApps -contains 11) {
    Write-Host "Installing: Lumi ProjectorPowerPoint Installer v2.22.0.0..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\Lumi ProjectorPowerPoint Installer v2.22.0.0.exe" -ArgumentList "/S" -PassThru
}

# 12) Lumi Register Installer v2.40.0.0
if ($selectedApps -contains 12) {
    Write-Host "Installing: Lumi Register Installer v2.40.0.0..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Register Installer v2.40.0.0.exe" -ArgumentList "/S" -PassThru
}

# 13) Lumi Signature Capture Installer v2.24.0.2
if ($selectedApps -contains 13) {
    Write-Host "Installing: Lumi Signature Capture Installer v2.24.0.2..." -ForegroundColor Green
    Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Signature Capture Installer v2.24.0.2.exe" -ArgumentList "/S" -PassThru
}


$ErrorActionPreference = 'Stop'

