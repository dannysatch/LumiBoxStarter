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

    Assert-FileExists $userSelections

    $regionConfig = Get-Content `
        -LiteralPath $userSelections `
        -Raw |
        ConvertFrom-Json

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
        'IML Communicator Hub Service Installer'
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

# -------------------------
# Projector HTML prerequisites
# -------------------------
if (Is-Selected -Needle 'Lumi Projector HTML Installer (Grid View)') {
    Write-Host 'Checking IIS for Projector HTML...' `
        -ForegroundColor Cyan

    $iisFeatures = @(
        'IIS-WebServerRole',
        'IIS-WebServer',
        'IIS-CommonHttpFeatures',
        'IIS-StaticContent',
        'IIS-DefaultDocument',
        'IIS-ManagementConsole'
    )

    $restartRequired = $false

    foreach ($feature in $iisFeatures) {
        $currentFeature = Get-WindowsOptionalFeature `
            -Online `
            -FeatureName $feature `
            -ErrorAction Stop

        if ($currentFeature.State -ne 'Enabled') {
            Write-Host "Enabling IIS feature: $feature"

            $result = Enable-WindowsOptionalFeature `
                -Online `
                -FeatureName $feature `
                -All `
                -NoRestart `
                -ErrorAction Stop

            if ($result.RestartNeeded) {
                $restartRequired = $true
            }
        }
    }

    if ($restartRequired) {
        Write-Host 'IIS requires a reboot before Projector HTML installation.' `
            -ForegroundColor Yellow

        Invoke-Reboot
    }

    foreach ($feature in $iisFeatures) {
        $state = Get-WindowsOptionalFeature `
            -Online `
            -FeatureName $feature `
            -ErrorAction Stop

        if ($state.State -ne 'Enabled') {
            throw "Required IIS feature is not enabled: $feature"
        }
    }

    Write-Host 'Required IIS features are enabled.' `
        -ForegroundColor Green
}

# ---- Names must match configStart.ps1 list (no versions) ----
Install-IfSelected 'IML Click System Installer'                 'IML Click System Installer v2.50.0.1.exe'                 'IML Click System Installer'
Install-IfSelected 'IML Communicator Hub Service Installer'     'IML Communicator Hub Service Installer v1.40.0.0.exe'     'IML Communicator Hub Service Installer'
Install-IfSelected 'IML Connector Configuration Tool Installer' 'IML Connector Configuration Tool Installer v3.52.0.0.exe' 'IML Connector Configuration Tool Installer'

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
Install-IfSelected 'Lumi Projector HTML Installer (Grid View)'  'Lumi Projector Html Installer v0.0.0.exe'                        'Lumi Projector HTML Installer (Grid View)'

# -------------------------
# Copy Connector firmware and updater to Lumi administrator desktop
# -------------------------
if (Is-Selected -Needle 'Connector Firmware and Updater Tool') {
    $allowedUsers = @(
        'LumiPcAdm',
        'LumiSvrAdm'
    )

    if ($env:USERNAME -notin $allowedUsers) {
        throw "Expected Boxstarter to run as LumiPcAdm or LumiSvrAdm, but current user is $env:USERNAME."
    }

    $sourceFolder = Join-Path `
        $installerRoot `
        'Connector Firmware and Updater Tool'

    if (-not (Test-Path -LiteralPath $sourceFolder -PathType Container)) {
        throw "Required folder not found: $sourceFolder"
    }

    $adminDesktop = [Environment]::GetFolderPath('Desktop')

    if ([string]::IsNullOrWhiteSpace($adminDesktop)) {
        throw "Could not resolve the desktop for $env:USERNAME."
    }

    $desktopFolder = Join-Path `
        $adminDesktop `
        'Connector Firmware and Updater Tool'

    # Remove the previous managed copy to avoid retaining old firmware
    if (Test-Path -LiteralPath $desktopFolder) {
        Remove-Item `
            -LiteralPath $desktopFolder `
            -Recurse `
            -Force `
            -ErrorAction Stop
    }

    Copy-Item `
        -LiteralPath $sourceFolder `
        -Destination $desktopFolder `
        -Recurse `
        -Force `
        -ErrorAction Stop

    if (-not (Test-Path -LiteralPath $desktopFolder -PathType Container)) {
        throw "Connector Firmware and Updater Tool was not copied to the desktop."
    }

    Write-Host `
        "Connector Firmware and Updater Tool copied to the desktop for $env:USERNAME." `
        -ForegroundColor Green
}

Install-IfSelected 'IML Connector System Installer'             'IML Connector System Installer v2.52.0.3.exe'             'IML Connector System Installer'

Install-IfSelected 'IML Connector Satellite Installer'          'IML Connector Satellite Installer v2.52.0.0.exe'          'IML Connector Satellite Installer'

# Add required Connector Satellite firewall rules after installation
if (Is-Selected -Needle 'IML Connector Satellite Installer') {
    $satelliteExe = 'C:\Program Files (x86)\IML\ConnectorSatellite\IMLConnectorSatellite.exe'

    Assert-FileExists $satelliteExe

    # Remove previous versions of these rules to prevent duplicates
    Get-NetFirewallRule `
        -DisplayName 'IMLConnectorSatellite' `
        -ErrorAction SilentlyContinue |
        Remove-NetFirewallRule

    New-NetFirewallRule `
        -Name 'IMLConnectorSatellite-TCP' `
        -DisplayName 'IMLConnectorSatellite' `
        -Direction Inbound `
        -Program $satelliteExe `
        -Protocol TCP `
        -Profile Private,Public `
        -Action Allow `
        -ErrorAction Stop |
        Out-Null

    New-NetFirewallRule `
        -Name 'IMLConnectorSatellite-UDP' `
        -DisplayName 'IMLConnectorSatellite' `
        -Direction Inbound `
        -Program $satelliteExe `
        -Protocol UDP `
        -Profile Private,Public `
        -Action Allow `
        -ErrorAction Stop |
        Out-Null

    Write-Host 'Connector Satellite TCP and UDP firewall rules created.' `
        -ForegroundColor Green
}

 ##### Canada Software Requests

    if ($regionConfig.Region -eq 'ca') {
        choco install onedrive -y
        choco install microsoft-teams-new-bootstrapper -y

        $ndiInstaller = Join-Path `
        $installerRoot `
        'NDI 6 Tools.exe'

        Assert-FileExists $ndiInstaller

        Start-Process `
            -FilePath $ndiInstaller `
            -ArgumentList @(
                '/VERYSILENT',
                '/SUPPRESSMSGBOXES',
                '/NORESTART',
                '/SP-'
            ) `
            -Wait
    }

Remove-Item -LiteralPath $userSelections -Force -ErrorAction SilentlyContinue
