# =========================
# Lumi Setup - fixed paths
# =========================

$ErrorActionPreference = 'Stop'

# --- Base paths / URLs ---
$workDir = 'C:\LumiSetup'
$zipUrl  = 'https://boxstarterlumi.blob.core.windows.net/installers/boxstarter.zip'

$zipFilePath     = Join-Path $workDir 'boxstarter.zip'
$userSelections  = Join-Path $workDir 'UserSelections.json'

# --- Flag files (NO leading slashes) ---
$DownloadFlag = Join-Path $workDir 'Download.flag'
$Script0Flag  = Join-Path $workDir 'Script0.flag'
$Script1Flag  = Join-Path $workDir 'Script1.flag'
$Script2Flag  = Join-Path $workDir 'Script2.flag'
$Script3Flag  = Join-Path $workDir 'Script3.flag'
$SQLFlag      = Join-Path $workDir 'SQL.flag'
$ConfigFlag   = Join-Path $workDir 'config.flag'
$OfficeFlag   = Join-Path $workDir 'Office.flag'

# --- Script / resource paths ---
$cmdAllowPowershell = Join-Path $workDir '0_AllowPowershell (right-click and run as administrator).cmd'
$script1            = Join-Path $workDir '1_LumiComputerSetup-AfterInstallingOS.ps1'
$script2            = Join-Path $workDir '2_LumiComputerSetup-AfterInstallingSQL.ps1'
$script3            = Join-Path $workDir '3_LumiComputerSetup-FinalSteps.ps1'
$configStart        = Join-Path $workDir 'configStart.ps1'

$officeConfigXml     = Join-Path $workDir 'Resources\MSOfficeInstallation\configuration.xml'

# Installer folder root
$installerRoot = Join-Path $workDir 'Lumi'

function New-FlagFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    New-Item -ItemType File -Path $Path -Force | Out-Null
}

# -------------------------
# Download Set Up Files
# -------------------------

# Ensure the work folder exists
if (-not (Test-Path -LiteralPath $workDir)) {
    New-Item -Path $workDir -ItemType Directory -Force | Out-Null
}

# Download + extract only once
if (-not (Test-Path -LiteralPath $DownloadFlag)) {

    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath

    Expand-Archive -LiteralPath $zipFilePath -DestinationPath $workDir -Force

    Remove-Item -LiteralPath $zipFilePath -Force -ErrorAction SilentlyContinue

    Write-Host "Files extracted to: $workDir"

    New-FlagFile -Path $DownloadFlag
}

# -------------------------
# Run Lumi Set Up Scripts
# -------------------------

# Script 0 (Set ExecutionPolicy) - run elevated cmd
if (-not (Test-Path -LiteralPath $Script0Flag)) {

    Start-Process -FilePath 'cmd.exe' `
        -ArgumentList @('/c', "`"$cmdAllowPowershell`"") `
        -Verb RunAs -Wait

    New-FlagFile -Path $Script0Flag
}

# Config - run elevated powershell script
if (-not (Test-Path -LiteralPath $ConfigFlag)) {

    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$configStart`"") `
        -Verb RunAs -Wait

    New-FlagFile -Path $ConfigFlag
}

# Load selections
$configJSON = Get-Content -LiteralPath $userSelections -Raw | ConvertFrom-Json

# Script 1 (your comment said Script 2, but this is Script 1)
if (-not (Test-Path -LiteralPath $Script1Flag)) {

    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$script1`"") `
        -Verb RunAs -Wait

    New-FlagFile -Path $Script1Flag

    Write-Host "`nRebooting to continue setup..."
    Invoke-Reboot
}

# SQL Setup
if (-not (Test-Path -LiteralPath $SQLFlag)) {

    # Install SQL Server Express
    choco install sql-server-express -y

    # Install SSMS
    choco install sql-server-management-studio -y

    New-FlagFile -Path $SQLFlag

    Write-Host "`nRebooting to continue setup..."
    Invoke-Reboot
}

# Script 2
if (-not (Test-Path -LiteralPath $Script2Flag)) {

    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$script2`"") `
        -Verb RunAs -Wait

    New-FlagFile -Path $Script2Flag
}

# Office Install
if (-not (Test-Path -LiteralPath $OfficeFlag)) {

    # mark first (so we don't retry forever if choco prompts / partially installs)
    New-FlagFile -Path $OfficeFlag

    # Chocolatey params quoting is finicky; this pattern is usually robust
    choco install office365business --params="'/configpath:$officeConfigXml'" -y
}

# Script 3
if (-not (Test-Path -LiteralPath $Script3Flag)) {

    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$script3`"") `
        -Verb RunAs -Wait

    New-FlagFile -Path $Script3Flag
}

# -------------------------
# Install Lumi Software
# -------------------------

$selectedApps = $configJSON.SelectedApplications

# Helper to build installer paths safely
function Get-InstallerPath {
    param(
        [Parameter(Mandatory)]
        [string]$FileName
    )
    return Join-Path $installerRoot $FileName
}

# 1) IML Communicator Hub Service Installer v1.40.0.0
if ($selectedApps -contains 1) {
    Write-Host "Installing: IML Communicator Hub Service Installer v1.40.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'IML Communicator Hub Service Installer v1.40.0.0.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 2) IML Connector System Installer v2.52.0.3
if ($selectedApps -contains 2) {
    Write-Host "Installing: IML Connector System Installer v2.52.0.3..." -ForegroundColor Green
    $exe = Get-InstallerPath 'IML Connector System Installer v2.52.0.3.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 3) Lumi AGM Installer v28.0.0.1 (AGM Core Install)
if ($selectedApps -contains 3) {
    Write-Host "Installing: Lumi AGM Installer v28.0.0.1..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi AGM Installer v28.0.0.1.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 4) Lumi AGM Reg and Vote Installer v3.10.0.0
if ($selectedApps -contains 4) {
    Write-Host "Installing: Lumi AGM Reg and Vote Installer v3.10.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi AGM Reg and Vote Installer v3.10.0.0.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 5) Lumi AGM Studio Installer v28.0.0.0
if ($selectedApps -contains 5) {
    Write-Host "Installing: Lumi AGM Studio Installer v28.0.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi AGM Studio Installer v28.0.0.0.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 6) Lumi Audience Display Installer v2.50.0.0
# NOTE: your numbering/comment says "6" but checks for 7; I left your logic intact.
if ($selectedApps -contains 7) {
    Write-Host "Installing: Lumi Audience Display Installer v2.50.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Audience Display Installer v2.50.0.0.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 7) Lumi Kiosk Browser Installer v28.0.0.0
if ($selectedApps -contains 8) {
    Write-Host "Installing: Lumi Kiosk Browser Installer v28.0.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Kiosk Browser Installer v28.0.0.0.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 8) Lumi Live DataBase Backup Installer v2.52.0.0
if ($selectedApps -contains 9) {
    Write-Host "Installing: Lumi Live DataBase Backup Installer v2.52.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Live DataBase Backup Installer v2.52.0.0.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 09) Lumi Magma Hub Service Installer v1.6.0.0
if ($selectedApps -contains 10) {
    Write-Host "Installing: Lumi Magma Hub Service Installer v1.6.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Magma Hub Service Installer v1.6.0.0.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 10) Lumi ProjectorPowerPoint Installer v2.24.0.0
if ($selectedApps -contains 11) {
    Write-Host "Installing: Lumi ProjectorPowerPoint Installer v2.24.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi ProjectorPowerPoint Installer v2.24.0.0.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 11) Lumi Register Installer v2.42.0.0
if ($selectedApps -contains 12) {
    Write-Host "Installing: Lumi Register Installer v2.42.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Register Installer v2.42.0.0.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 12) Lumi Signature Capture Installer v2.26.0.0
if ($selectedApps -contains 13) {
    Write-Host "Installing: Lumi Signature Capture Installer v2.26.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Signature Capture Installer v2.26.0.0.exe'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# Cleanup
Remove-Item -LiteralPath $userSelections -Force -ErrorAction SilentlyContinue
