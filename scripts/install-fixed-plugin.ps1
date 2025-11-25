# Install Fixed Scene Tree View Plugin to OBS Studio
# This script installs the fixed plugin DLL that resolves the empty dock issue

param(
    [switch]$WhatIf = $false
)

$ErrorActionPreference = "Stop"

# Paths
$SourceDLL = "D:\Coding\obs-plugins\obs_scene_tree_view\build_qt683\RelWithDebInfo\obs_scene_tree_view.dll"
$TargetDLL = "C:\Program Files\obs-studio\obs-plugins\64bit\obs_scene_tree_view.dll"

Write-Host "=== Scene Tree View Plugin Installation ===" -ForegroundColor Cyan
Write-Host ""

# Check if source DLL exists
if (-not (Test-Path $SourceDLL)) {
    Write-Host "ERROR: Source DLL not found at:" -ForegroundColor Red
    Write-Host "  $SourceDLL" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please build the plugin first using:" -ForegroundColor Yellow
    Write-Host "  cmake --build build_qt683 --config RelWithDebInfo" -ForegroundColor Yellow
    exit 1
}

# Get source DLL info
$SourceInfo = Get-Item $SourceDLL
Write-Host "Source DLL:" -ForegroundColor Green
Write-Host "  Path: $SourceDLL"
Write-Host "  Size: $($SourceInfo.Length) bytes"
Write-Host "  Modified: $($SourceInfo.LastWriteTime)"
Write-Host ""

# Check if OBS is running
$OBSProcess = Get-Process -Name "obs64" -ErrorAction SilentlyContinue
if ($OBSProcess) {
    Write-Host "WARNING: OBS Studio is currently running!" -ForegroundColor Yellow
    Write-Host "Please close OBS Studio before installing the plugin." -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Do you want to close OBS now? (y/n)"
    if ($response -eq 'y') {
        Write-Host "Closing OBS Studio..." -ForegroundColor Yellow
        Stop-Process -Name "obs64" -Force
        Start-Sleep -Seconds 2
    } else {
        Write-Host "Installation cancelled." -ForegroundColor Red
        exit 1
    }
}

# Check if target directory exists
$TargetDir = Split-Path $TargetDLL -Parent
if (-not (Test-Path $TargetDir)) {
    Write-Host "ERROR: OBS plugins directory not found:" -ForegroundColor Red
    Write-Host "  $TargetDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure OBS Studio is installed at:" -ForegroundColor Yellow
    Write-Host "  C:\Program Files\obs-studio\" -ForegroundColor Yellow
    exit 1
}

# Backup existing DLL if it exists
if (Test-Path $TargetDLL) {
    $BackupPath = "$TargetDLL.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "Backing up existing DLL to:" -ForegroundColor Yellow
    Write-Host "  $BackupPath"
    
    if (-not $WhatIf) {
        Copy-Item $TargetDLL $BackupPath -Force
    }
    Write-Host ""
}

# Install the DLL
Write-Host "Installing fixed plugin DLL..." -ForegroundColor Green
Write-Host "  From: $SourceDLL"
Write-Host "  To:   $TargetDLL"
Write-Host ""

if ($WhatIf) {
    Write-Host "[WHATIF] Would copy DLL (use without -WhatIf to actually install)" -ForegroundColor Cyan
} else {
    try {
        Copy-Item $SourceDLL $TargetDLL -Force
        Write-Host "SUCCESS: Plugin installed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Launch OBS Studio"
        Write-Host "  2. Enable the dock: View → Docks → Scene Tree View"
        Write-Host "  3. Test the dock in different positions:"
        Write-Host "     - Left of video preview"
        Write-Host "     - Tabbed with other docks"
        Write-Host "     - Bottom, right, floating"
        Write-Host "  4. Close and reopen OBS to verify the fix"
        Write-Host ""
        Write-Host "Check the logs for confirmation:" -ForegroundColor Cyan
        Write-Host "  Help → Log Files → View Current Log"
        Write-Host "  Search for: [SceneTreeView] registered via add_custom_qdock"
        Write-Host ""
    } catch {
        Write-Host "ERROR: Failed to install plugin!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
        Write-Host "You may need to run this script as Administrator." -ForegroundColor Yellow
        exit 1
    }
}

