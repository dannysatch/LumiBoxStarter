$workDir = "C:\LumiSetup\" 
$zipUrl = "https://boxstarterlumi.blob.core.windows.net/installers/boxstarter.zip"
$zipFilePath = Join-Path $workDir "boxstarter.zip"

$DownloadFlag = Join-Path $workDir "Download.flag"
$Script0Flag = Join-Path $workDir "Script0.flag"
$Script2Flag = Join-Path $workDir "Script2.flag"
$Script3Flag = Join-Path $workDir "Script3.flag"
$SQLFlag =  Join-Path $workDir "SQL.flag"
$Script4Flag = Join-Path $workDir "Script4.flag"
$OfficeFlag = Join-Path $workDir "Office.flag"
$Script6Flag = Join-Path $workDir "Script6.flag"
$Script7Flag = Join-Path $workDir "Script7.flag"
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

}


# Script 0 (Set ExecutionPolicy)
if (-not (Test-Path $Script0Flag)) {
    
    Start-Process "cmd.exe" -ArgumentList "/c `"$workDir\0_AllowPowershell (right-click and run as administrator).cmd`"" -Verb RunAs -Wait

    New-Item -ItemType File -Path "$workDir\Script0.flag" | Out-Null

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

# Script 4
if (-not (Test-Path $Script4Flag)) {
    
    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\4_LumiComputerSetup-AfterInstallingSqlExpress.ps1`"" -Verb RunAs -Wait
    New-Item -ItemType File -Path "$workDir\Script4.flag" | Out-Null

}

# Office Install
if (-not (Test-Path $OfficeFlag)) {
    
    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\5_LumiComputerSetup-InstallOffice.ps1`"" -Verb RunAs -Wait
    New-Item -ItemType File -Path "$workDir\Office.flag" | Out-Null

}

# # Run Windows Updates
# Install-WindowsUpdate -AcceptEula

# # Script 6
# if (-not (Test-Path $Script6Flag)) {
    
#     Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\6_LumiComputerSetup-AfterInstallingWindowsUpdates.ps1`"" -Verb RunAs -Wait
#     New-Item -ItemType File -Path "$workDir\Script6.flag" | Out-Null

# }

# # Script 7

# if (-not (Test-Path $Script7Flag)) {
    
#     Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$workDir\Fix LumiAGM log and addin file permissions.ps1`"" -Verb RunAs -Wait
#     New-Item -ItemType File -Path "$workDir\Script7.flag" | Out-Null

# }

# AGM Core Install
Start-Process -Wait -FilePath "$workDir\Lumi\Lumi AGM Installer v27.0.0.1.exe" -ArgumentList "/S" -PassThru

# IML Communicator Hub Service Installer v1.38.0.0
Start-Process -Wait -FilePath "$workDir\Lumi\IML Communicator Hub Service Installer v1.38.0.0.exe" -ArgumentList "/S" -PassThru

# IML Connector System Installer v2.50.0.0
Start-Process -Wait -FilePath "$workDir\Lumi\IML Connector System Installer v2.50.0.0.exe" -ArgumentList "/S" -PassThru

# Lumi AGM Reg and Vote Installer v3.8.0.1
Start-Process -Wait -FilePath "$workDir\Lumi\Lumi AGM Reg and Vote Installer v3.8.0.1.exe" -ArgumentList "/S" -PassThru

# Lumi AGM Studio Installer v27.0.0.0
Start-Process -Wait -FilePath "$workDir\Lumi\Lumi AGM Studio Installer v27.0.0.0.exe" -ArgumentList "/S" -PassThru

# Lumi AGM Web Apps Installer v27.0.0.0
Start-Process -Wait -FilePath "$workDir\Lumi\Lumi AGM Web Apps Installer v27.0.0.0.exe" -ArgumentList "/S" -PassThru

# Lumi Audience Display Installer v2.48.0.0
Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Audience Display Installer v2.48.0.0.exe" -ArgumentList "/S" -PassThru

# Lumi Kiosk Browser Installer v27.0.0.2
Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Kiosk Browser Installer v27.0.0.2.exe" -ArgumentList "/S" -PassThru

# Lumi Live DataBase Backup Installer v2.50.0.0
Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Live DataBase Backup Installer v2.50.0.0.exe" -ArgumentList "/S" -PassThru

# Lumi Magma Hub Service Installer v1.4.0.0
Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Magma Hub Service Installer v1.4.0.0.exe" -ArgumentList "/S" -PassThru

# Lumi ProjectorPowerPoint Installer v2.22.0.0
Start-Process -Wait -FilePath "$workDir\Lumi\Lumi ProjectorPowerPoint Installer v2.22.0.0.exe" -ArgumentList "/S" -PassThru

# Lumi Register Installer v2.40.0.0
Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Register Installer v2.40.0.0.exe" -ArgumentList "/S" -PassThru

# Lumi Signature Capture Installer v2.24.0.2
Start-Process -Wait -FilePath "$workDir\Lumi\Lumi Signature Capture Installer v2.24.0.2.exe" -ArgumentList "/S" -PassThru


$ErrorActionPreference = 'Stop'

