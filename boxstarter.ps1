# =========================
# Lumi Setup - corrected for /boxstarter folder
# =========================

$ErrorActionPreference = 'Stop'

# --- Base paths ---
$workDir     = 'C:\LumiSetup'
$packageRoot = Join-Path $workDir 'boxstarter'
$zipUrl      = 'https://boxstarterlumi.blob.core.windows.net/installers/boxstarter.zip'

$zipFilePath    = Join-Path $workDir 'boxstarter.zip'
$userSelections = Join-Path $packageRoot 'UserSelections.json'

# --- Flag files stay in C:\LumiSetup ---
$DownloadFlag = Join-Path $workDir 'Download.flag'
$Script0Flag  = Join-Path $workDir 'Script0.flag'
$Script1Flag  = Join-Path $workDir 'Script1.flag'
$Script2Flag  = Join-Path $workDir 'Script2.flag'
$Script3Flag  = Join-Path $workDir 'Script3.flag'
$SQLFlag      = Join-Path $workDir 'SQL.flag'
$ConfigFlag   = Join-Path $workDir 'config.flag'
$OfficeFlag   = Join-Path $workDir 'Office.flag'

# --- Script paths (NOW under boxstarter folder) ---
$cmdAllowPowershell = Join-Path $packageRoot '0_AllowPowershell (right-click and run as administrator).cmd'
$script1            = Join-Path $packageRoot '1_LumiComputerSetup-AfterInstallingOS.ps1'
$script2            = Join-Path $packageRoot '2_LumiComputerSetup-AfterInstallingSQL.ps1'
$script3            = Join-Path $packageRoot '3_LumiComputerSetup-FinalSteps.ps1'
$configStart        = Join-Path $packageRoot 'configStart.ps1'

$officeConfigXml = Join-Path $packageRoot 'Resources\MSOfficeInstallation\configuration.xml'
$installerRoot   = Join-Path $packageRoot 'Lumi'

function New-FlagFile($Path) {
    New-Item -ItemType File -Path $Path -Force | Out-Null
}

function Assert-FileExists($Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required file not found: $Path"
    }
}

# -------------------------
# Ensure work folder exists
# -------------------------
if (-not (Test-Path $workDir)) {
    New-Item -Path $workDir -ItemType Directory -Force | Out-Null
}

# -------------------------
# Download + Extract
# -------------------------
if (-not (Test-Path $DownloadFlag)) {

    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath

    Expand-Archive -LiteralPath $zipFilePath -DestinationPath $workDir -Force

    Remove-Item $zipFilePath -Force

    New-FlagFile $DownloadFlag
}

# -------------------------
# Script 0
# -------------------------
if (-not (Test-Path $Script0Flag)) {

    Assert-FileExists $cmdAllowPowershell

    Start-Process 'cmd.exe' `
        -ArgumentList @('/c', "`"$cmdAllowPowershell`"") `
        -Verb RunAs -Wait

    New-FlagFile $Script0Flag
}

# -------------------------
# Config
# -------------------------
if (-not (Test-Path $ConfigFlag)) {

    Assert-FileExists $configStart

    Start-Process 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$configStart`"") `
        -Verb RunAs -Wait

    New-FlagFile $ConfigFlag
}

# -------------------------
# Script 1
# -------------------------
if (-not (Test-Path $Script1Flag)) {

    Assert-FileExists $script1

    Start-Process 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$script1`"") `
        -Verb RunAs -Wait

    New-FlagFile $Script1Flag
    Invoke-Reboot
}

# -------------------------
# SQL
# -------------------------
if (-not (Test-Path $SQLFlag)) {

    choco install sql-server-express -y
    choco install sql-server-management-studio -y

    New-FlagFile $SQLFlag
    Invoke-Reboot
}

# -------------------------
# Script 2
# -------------------------
if (-not (Test-Path $Script2Flag)) {

    Assert-FileExists $script2

    Start-Process 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$script2`"") `
        -Verb RunAs -Wait

    New-FlagFile $Script2Flag
}

# -------------------------
# Office
# -------------------------
if (-not (Test-Path $OfficeFlag)) {

    Assert-FileExists $officeConfigXml

    New-FlagFile $OfficeFlag

    choco install office365business --params="'/configpath:$officeConfigXml'" -y
}

# -------------------------
# Script 3
# -------------------------
if (-not (Test-Path $Script3Flag)) {

    Assert-FileExists $script3

    Start-Process 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$script3`"") `
        -Verb RunAs -Wait

    New-FlagFile $Script3Flag
}

# -------------------------
# Load selections (NOW CORRECT ROOT)
# -------------------------
Assert-FileExists $userSelections
$configJSON = Get-Content $userSelections -Raw | ConvertFrom-Json
$selectedApps = $configJSON.SelectedApplications

function Install-App($id, $filename, $name) {
    if ($selectedApps -contains $id) {
        $path = Join-Path $installerRoot $filename
        Assert-FileExists $path
        Write-Host "Installing: $name" -ForegroundColor Green
        Start-Process -Wait -FilePath $path -ArgumentList '/S'
    }
}

Install-App 1  'IML Communicator Hub Service Installer v1.40.0.0.exe' 'IML Communicator Hub'
Install-App 2  'IML Connector System Installer v2.52.0.3.exe'         'IML Connector System'
Install-App 3  'Lumi AGM Installer v28.0.0.1.exe'                     'Lumi AGM'
Install-App 4  'Lumi AGM Reg and Vote Installer v3.10.0.0.exe'        'Lumi AGM Reg and Vote'
Install-App 5  'Lumi AGM Studio Installer v28.0.0.0.exe'              'Lumi AGM Studio'
Install-App 7  'Lumi Audience Display Installer v2.50.0.0.exe'        'Lumi Audience Display'
Install-App 8  'Lumi Kiosk Browser Installer v28.0.0.0.exe'           'Lumi Kiosk Browser'
Install-App 9  'Lumi Live DataBase Backup Installer v2.52.0.0.exe'    'Lumi Live Database Backup'
Install-App 10 'Lumi Magma Hub Service Installer v1.6.0.0.exe'        'Lumi Magma Hub'
Install-App 11 'Lumi ProjectorPowerPoint Installer v2.24.0.0.exe'     'Lumi Projector PowerPoint'
Install-App 12 'Lumi Register Installer v2.42.0.0.exe'                 'Lumi Register'
Install-App 13 'Lumi Signature Capture Installer v2.26.0.0.exe'       'Lumi Signature Capture'

Remove-Item $userSelections -Force -ErrorAction SilentlyContinue
