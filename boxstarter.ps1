# =========================
# Lumi Setup - corrected script (paths + ordering)
# =========================

$ErrorActionPreference = 'Stop'

# --- Base paths / URLs ---
$workDir = 'C:\LumiSetup'
$zipUrl  = 'https://boxstarterlumi.blob.core.windows.net/installers/boxstarter.zip'

$zipFilePath    = Join-Path $workDir 'boxstarter.zip'
$userSelections = Join-Path $workDir 'UserSelections.json'

# --- Flag files ---
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

$officeConfigXml = Join-Path $workDir 'Resources\MSOfficeInstallation\configuration.xml'

# --- Installer folder root ---
$installerRoot = Join-Path $workDir 'Lumi'

function New-FlagFile {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -ItemType File -Path $Path -Force | Out-Null
}

function Assert-FileExists {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Name was not found at: $Path"
    }
}

function Get-InstallerPath {
    param([Parameter(Mandatory)][string]$FileName)
    Join-Path $installerRoot $FileName
}

# -------------------------
# Download Set Up Files
# -------------------------

if (-not (Test-Path -LiteralPath $workDir)) {
    New-Item -Path $workDir -ItemType Directory -Force | Out-Null
}

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

# Script 0 (Set ExecutionPolicy)
if (-not (Test-Path -LiteralPath $Script0Flag)) {

    Assert-FileExists -Path $cmdAllowPowershell -Name 'Script0 CMD file'

    Start-Process -FilePath 'cmd.exe' `
        -ArgumentList @('/c', "`"$cmdAllowPowershell`"") `
        -Verb RunAs -Wait

    New-FlagFile -Path $Script0Flag
}

# Config
if (-not (Test-Path -LiteralPath $ConfigFlag)) {

    Assert-FileExists -Path $configStart -Name 'configStart.ps1'

    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$configStart`"") `
        -Verb RunAs -Wait

    # configStart.ps1 is expected to create UserSelections.json
    if (-not (Test-Path -LiteralPath $userSelections)) {
        Write-Warning "UserSelections.json not found immediately after configStart.ps1. If configStart writes it later, that's OK. Path expected: $userSelections"
    }

    New-FlagFile -Path $ConfigFlag
}

# Script 1
if (-not (Test-Path -LiteralPath $Script1Flag)) {

    Assert-FileExists -Path $script1 -Name '1_LumiComputerSetup-AfterInstallingOS.ps1'

    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$script1`"") `
        -Verb RunAs -Wait

    New-FlagFile -Path $Script1Flag

    Write-Host "`nRebooting to continue setup..."
    Invoke-Reboot
}

# SQL Setup
if (-not (Test-Path -LiteralPath $SQLFlag)) {

    choco install sql-server-express -y
    choco install sql-server-management-studio -y

    New-FlagFile -Path $SQLFlag

    Write-Host "`nRebooting to continue setup..."
    Invoke-Reboot
}

# Script 2
if (-not (Test-Path -LiteralPath $Script2Flag)) {

    Assert-FileExists -Path $script2 -Name '2_LumiComputerSetup-AfterInstallingSQL.ps1'

    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$script2`"") `
        -Verb RunAs -Wait

    New-FlagFile -Path $Script2Flag
}

# Office Install
if (-not (Test-Path -LiteralPath $OfficeFlag)) {

    # mark first (prevents endless retries if install partially completes)
    New-FlagFile -Path $OfficeFlag

    # Ensure config XML exists
    Assert-FileExists -Path $officeConfigXml -Name 'Office configuration.xml'

    # Chocolatey params quoting is finicky; this pattern is usually robust
    choco install office365business --params="'/configpath:$officeConfigXml'" -y
}

# Script 3
if (-not (Test-Path -LiteralPath $Script3Flag)) {

    Assert-FileExists -Path $script3 -Name '3_LumiComputerSetup-FinalSteps.ps1'

    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$script3`"") `
        -Verb RunAs -Wait

    New-FlagFile -Path $Script3Flag
}

# -------------------------
# Install Lumi Software
# IMPORTANT: load selections ONLY here (after config stage)
# -------------------------

Assert-FileExists -Path $userSelections -Name 'UserSelections.json'
$configJSON = Get-Content -LiteralPath $userSelections -Raw | ConvertFrom-Json

$selectedApps = $configJSON.SelectedApplications

# 1) IML Communicator Hub Service Installer v1.40.0.0
if ($selectedApps -contains 1) {
    Write-Host "Installing: IML Communicator Hub Service Installer v1.40.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'IML Communicator Hub Service Installer v1.40.0.0.exe'
    Assert-FileExists -Path $exe -Name 'IML Communicator Hub Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 2) IML Connector System Installer v2.52.0.3
if ($selectedApps -contains 2) {
    Write-Host "Installing: IML Connector System Installer v2.52.0.3..." -ForegroundColor Green
    $exe = Get-InstallerPath 'IML Connector System Installer v2.52.0.3.exe'
    Assert-FileExists -Path $exe -Name 'IML Connector System Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 3) Lumi AGM Installer v28.0.0.1 (AGM Core Install)
if ($selectedApps -contains 3) {
    Write-Host "Installing: Lumi AGM Installer v28.0.0.1..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi AGM Installer v28.0.0.1.exe'
    Assert-FileExists -Path $exe -Name 'Lumi AGM Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 4) Lumi AGM Reg and Vote Installer v3.10.0.0
if ($selectedApps -contains 4) {
    Write-Host "Installing: Lumi AGM Reg and Vote Installer v3.10.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi AGM Reg and Vote Installer v3.10.0.0.exe'
    Assert-FileExists -Path $exe -Name 'Lumi AGM Reg and Vote Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 5) Lumi AGM Studio Installer v28.0.0.0
if ($selectedApps -contains 5) {
    Write-Host "Installing: Lumi AGM Studio Installer v28.0.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi AGM Studio Installer v28.0.0.0.exe'
    Assert-FileExists -Path $exe -Name 'Lumi AGM Studio Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 6) Lumi Audience Display Installer v2.50.0.0
# NOTE: your original script checks for 7 here; kept as-is to match your selections mapping.
if ($selectedApps -contains 7) {
    Write-Host "Installing: Lumi Audience Display Installer v2.50.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Audience Display Installer v2.50.0.0.exe'
    Assert-FileExists -Path $exe -Name 'Lumi Audience Display Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 7) Lumi Kiosk Browser Installer v28.0.0.0
if ($selectedApps -contains 8) {
    Write-Host "Installing: Lumi Kiosk Browser Installer v28.0.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Kiosk Browser Installer v28.0.0.0.exe'
    Assert-FileExists -Path $exe -Name 'Lumi Kiosk Browser Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 8) Lumi Live DataBase Backup Installer v2.52.0.0
if ($selectedApps -contains 9) {
    Write-Host "Installing: Lumi Live DataBase Backup Installer v2.52.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Live DataBase Backup Installer v2.52.0.0.exe'
    Assert-FileExists -Path $exe -Name 'Lumi Live DataBase Backup Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 09) Lumi Magma Hub Service Installer v1.6.0.0
if ($selectedApps -contains 10) {
    Write-Host "Installing: Lumi Magma Hub Service Installer v1.6.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Magma Hub Service Installer v1.6.0.0.exe'
    Assert-FileExists -Path $exe -Name 'Lumi Magma Hub Service Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 10) Lumi ProjectorPowerPoint Installer v2.24.0.0
if ($selectedApps -contains 11) {
    Write-Host "Installing: Lumi ProjectorPowerPoint Installer v2.24.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi ProjectorPowerPoint Installer v2.24.0.0.exe'
    Assert-FileExists -Path $exe -Name 'Lumi ProjectorPowerPoint Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 11) Lumi Register Installer v2.42.0.0
if ($selectedApps -contains 12) {
    Write-Host "Installing: Lumi Register Installer v2.42.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Register Installer v2.42.0.0.exe'
    Assert-FileExists -Path $exe -Name 'Lumi Register Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# 12) Lumi Signature Capture Installer v2.26.0.0
if ($selectedApps -contains 13) {
    Write-Host "Installing: Lumi Signature Capture Installer v2.26.0.0..." -ForegroundColor Green
    $exe = Get-InstallerPath 'Lumi Signature Capture Installer v2.26.0.0.exe'
    Assert-FileExists -Path $exe -Name 'Lumi Signature Capture Installer'
    Start-Process -Wait -FilePath $exe -ArgumentList '/S' -PassThru
}

# Cleanup
Remove-Item -LiteralPath $userSelections -Force -ErrorAction SilentlyContinue
