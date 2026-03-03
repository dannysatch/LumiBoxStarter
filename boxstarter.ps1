# =========================
# Lumi Setup - corrected for /boxstarter folder (with tweaks applied)
# =========================

$ErrorActionPreference = 'Stop'

# --- Base paths ---
$workDir     = 'C:\LumiSetup'
$packageRoot = Join-Path $workDir 'boxstarter'
$zipUrl      = 'https://boxstarterlumi.blob.core.windows.net/installers/boxstarter.zip'

$zipFilePath    = Join-Path $workDir 'boxstarter.zip'
$userSelections = Join-Path $workDir 'UserSelections.json'

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
if (-not (Test-Path -LiteralPath $workDir)) {
    New-Item -Path $workDir -ItemType Directory -Force | Out-Null
}

# -------------------------
# Download + Extract
# -------------------------
if (-not (Test-Path -LiteralPath $DownloadFlag)) {

    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath

    Expand-Archive -LiteralPath $zipFilePath -DestinationPath $workDir -Force

    Remove-Item -LiteralPath $zipFilePath -Force -ErrorAction SilentlyContinue

    # Sanity-check extracted structure
    if (-not (Test-Path -LiteralPath $packageRoot)) {
        throw "Expected extracted folder not found: $packageRoot"
    }

    New-FlagFile $DownloadFlag
}

# -------------------------
# Script 0
# -------------------------
if (-not (Test-Path -LiteralPath $Script0Flag)) {

    Assert-FileExists $cmdAllowPowershell

    Start-Process 'cmd.exe' `
        -ArgumentList @('/c', "`"$cmdAllowPowershell`"") `
        -Verb RunAs -Wait

    New-FlagFile $Script0Flag
}

# -------------------------
# Config
# -------------------------
if (-not (Test-Path -LiteralPath $ConfigFlag)) {

    Assert-FileExists $configStart

    Start-Process 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$configStart`"") `
        -Verb RunAs -Wait

    New-FlagFile $ConfigFlag
}

# -------------------------
# Script 1
# -------------------------
if (-not (Test-Path -LiteralPath $Script1Flag)) {

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
if (-not (Test-Path -LiteralPath $SQLFlag)) {

    choco install sql-server-express -y
    choco install sql-server-management-studio -y

    #####UK Software Requests
    choco install googlechrome -y
    choco install zoom -y
    choco install tightvnc -y
    choco install notepadplusplus.install -y
    choco install 7zip.install -y
    choco install dotnet3.5 -y

    New-FlagFile $SQLFlag
    Invoke-Reboot
}

# -------------------------
# Script 2
# -------------------------
if (-not (Test-Path -LiteralPath $Script2Flag)) {

    Assert-FileExists $script2

    Start-Process 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$script2`"") `
        -Verb RunAs -Wait

    New-FlagFile $Script2Flag
}

# -------------------------
# Office
# -------------------------
if (-not (Test-Path -LiteralPath $OfficeFlag)) {

    Assert-FileExists $officeConfigXml

    # Install first; only mark completed when successful
    choco install office365business --params="'/configpath:$officeConfigXml'" -y

    New-FlagFile $OfficeFlag
}

# -------------------------
# Script 3
# -------------------------
if (-not (Test-Path -LiteralPath $Script3Flag)) {

    Assert-FileExists $script3

    Start-Process 'powershell.exe' `
        -ArgumentList @('-ExecutionPolicy','Bypass','-NoProfile','-File',"`"$script3`"") `
        -Verb RunAs -Wait

    New-FlagFile $Script3Flag
}

# -------------------------
# Install Lumi Software (payload ZIP binaries)
# -------------------------

Assert-FileExists $userSelections
$configJSON = Get-Content -LiteralPath $userSelections -Raw | ConvertFrom-Json

$selectedApps = @($configJSON.SelectedApplications)

function Is-Selected {
    param([Parameter(Mandatory)][string]$Needle)

    return [bool]($selectedApps | Where-Object { $_ -like "*$Needle*" } | Select-Object -First 1)
}

function Install-IfSelected {
    param(
        [Parameter(Mandatory)][string]$SelectionNeedle,  # NO version string
        [Parameter(Mandatory)][string]$ExeFileName,      # versioned exe in ZIP
        [Parameter(Mandatory)][string]$DisplayName
    )
    # QUICK HOTFIX: never install these (even if selected/all)
    if ($DisplayName -in @(
        'Lumi Feedback Hub Service Installer',
        'IML Communicator Hub Service Installer',
        'Lumi Audience Display Installer'
    )) {
        Write-Host "FORCED SKIP: $DisplayName" -ForegroundColor Yellow
        return
    }
    if (Is-Selected -Needle $SelectionNeedle) {
        $exePath = Join-Path $installerRoot $ExeFileName
        Assert-FileExists $exePath
        Write-Host "Installing: $DisplayName" -ForegroundColor Green
        Start-Process -Wait -FilePath $exePath -ArgumentList '/S' -PassThru | Out-Null
    }
    else {
        Write-Host "Skipping (not selected): $DisplayName" -ForegroundColor DarkGray
    }
}

# ---- Names must match configStart.ps1 list (no versions) ----
Install-IfSelected 'IML Click System Installer'                 'IML Click System Installer v2.50.0.1.exe'                 'IML Click System Installer'
Install-IfSelected 'IML Communicator Hub Service Installer'     'IML Communicator Hub Service Installer v1.40.0.0.exe'     'IML Communicator Hub Service Installer'
Install-IfSelected 'IML Connector Configuration Tool Installer' 'IML Connector Configuration Tool Installer v3.52.0.0.exe' 'IML Connector Configuration Tool Installer'
Install-IfSelected 'IML Connector Satellite Installer'          'IML Connector Satellite Installer v2.52.0.0.exe'          'IML Connector Satellite Installer'
Install-IfSelected 'IML Connector System Installer'             'IML Connector System Installer v2.52.0.3.exe'             'IML Connector System Installer'

Install-IfSelected 'Lumi AGM Installer'                         'Lumi AGM Installer v28.0.0.1.exe'                         'Lumi AGM Installer'
Install-IfSelected 'Lumi AGM Reg and Vote Installer'            'Lumi AGM Reg and Vote Installer v3.10.0.0.exe'            'Lumi AGM Reg and Vote Installer'
Install-IfSelected 'Lumi AGM Studio Installer'                  'Lumi AGM Studio Installer v28.0.0.0.exe'                  'Lumi AGM Studio Installer'

Install-IfSelected 'Lumi Audience Display Installer'            'Lumi Audience Display Installer v2.50.0.0.exe'            'Lumi Audience Display Installer'
Install-IfSelected 'Lumi Live DataBase Backup Installer'        'Lumi Live DataBase Backup Installer v2.52.0.0.exe'        'Lumi Live DataBase Backup Installer'
Install-IfSelected 'Lumi ProjectorPowerPoint Installer'         'Lumi ProjectorPowerPoint Installer v2.24.0.0.exe'         'Lumi ProjectorPowerPoint Installer'
Install-IfSelected 'Lumi Register Installer'                    'Lumi Register Installer v2.42.0.0.exe'                    'Lumi Register Installer'
Install-IfSelected 'Lumi Signature Capture Installer'           'Lumi Signature Capture Installer v2.26.0.0.exe'           'Lumi Signature Capture Installer'

Install-IfSelected 'Lumi Feedback Hub Service Installer'        'Lumi Feedback Hub Service Installer v1.16.0.0.exe'        'Lumi Feedback Hub Service Installer'
Install-IfSelected 'Lumi Kiosk Browser Installer'               'Lumi Kiosk Browser Installer v28.0.0.0.exe'               'Lumi Kiosk Browser Installer'
Install-IfSelected 'Lumi Magma Hub Service Installer'           'Lumi Magma Hub Service Installer v1.6.0.0.exe'            'Lumi Magma Hub Service Installer'
Install-IfSelected 'Lumi Studio Installer'                      'Lumi Studio Installer v1.38.0.0.exe'                      'Lumi Studio Installer'

Remove-Item -LiteralPath $userSelections -Force -ErrorAction SilentlyContinue
