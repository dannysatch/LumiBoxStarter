# Lumi Setup Configuration Collector (fixed)
# Saves to C:\LumiSetup\UserSelections.json

# Ensure output directory exists
$outputDir = "C:\LumiSetup"
if (-not (Test-Path $outputDir)) { New-Item -Path $outputDir -ItemType Directory | Out-Null }
$outputFile = Join-Path $outputDir "UserSelections.json"

Write-Host "=== Lumi Setup Configuration ===" -ForegroundColor Cyan

# Prompt for basic info
$computerName = Read-Host "Enter Computer Name"
$lumiOpPassword = Read-Host "Enter LumiOp Password" -AsSecureString
$lumiAdminPassword = Read-Host "Enter Lumi Admin Password" -AsSecureString

# Store DPAPI-protected strings (no extra Base64 needed)
$lumiOpPasswordEnc    = ConvertFrom-SecureString -SecureString $lumiOpPassword
$lumiAdminPasswordEnc = ConvertFrom-SecureString -SecureString $lumiAdminPassword

# Yes/No for server features
$serverFeaturesInput = Read-Host "Install Server Features? (Yes/No)"
$serverFeatures = ($serverFeaturesInput -match '^(y|yes)$')

# Lumi Applications
$applications = @(
    "IML Communicator Hub Service Installer v1.38.0.0",
    "IML Connector System Installer v2.50.0.0",
    "Lumi AGM Installer v27.0.0.1",
    "Lumi AGM Reg and Vote Installer v3.8.0.1",
    "Lumi AGM Studio Installer v27.0.0.0",
    "Lumi AGM Web Apps Installer v27.0.0.0",
    "Lumi Audience Display Installer v2.48.0.0",
    "Lumi Kiosk Browser Installer v27.0.0.2",
    "Lumi Live DataBase Backup Installer v2.50.0.0",
    "Lumi Magma Hub Service Installer v1.4.0.0",
    "Lumi ProjectorPowerPoint Installer v2.22.0.0",
    "Lumi Register Installer v2.40.0.0",
    "Lumi Signature Capture Installer v2.24.0.2"
)

Write-Host "`nSelect Lumi applications to install:" -ForegroundColor Cyan
Write-Host "Enter numbers separated by commas, or type 'all' to select everything.`n" -ForegroundColor Yellow

for ($i = 0; $i -lt $applications.Count; $i++) {
    Write-Host ("{0,2}) {1}" -f ($i + 1), $applications[$i])
}

$appChoice = Read-Host "`nYour selection"
if ($appChoice -match '^(all|a)$') {
    $selectedApps = $applications
} else {
    $indexes = $appChoice -split '[,\s]+' | Where-Object { $_ -match '^\d+$' }
    $selectedApps = foreach ($i in $indexes) {
        if ($i -ge 1 -and $i -le $applications.Count) { $applications[$i - 1] }
    }
}

# Build config object
$config = [PSCustomObject]@{
    ComputerName         = $computerName
    LumiOpPassword       = $lumiOpPasswordEnc       # DPAPI-protected string
    LumiAdminPassword    = $lumiAdminPasswordEnc    # DPAPI-protected string
    ServerFeatures       = $serverFeatures
    SelectedApplications = $selectedApps
}

# Save to JSON
$config | ConvertTo-Json -Depth 6 | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`nConfiguration saved to $outputFile" -ForegroundColor Green
Write-Host "You can decrypt later with:  ConvertTo-SecureString <value>"
[void][System.Console]::ReadKey($true)
