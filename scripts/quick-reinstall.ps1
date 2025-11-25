# Quick reinstall script - closes OBS, copies DLL, restarts OBS
$ErrorActionPreference = "Stop"

Write-Host "=== Quick Reinstall Scene Tree View Plugin ===" -ForegroundColor Cyan
Write-Host ""

# Close OBS if running
$OBSProcess = Get-Process -Name "obs64" -ErrorAction SilentlyContinue
if ($OBSProcess) {
    Write-Host "Closing OBS Studio..." -ForegroundColor Yellow
    Stop-Process -Name "obs64" -Force
    Start-Sleep -Seconds 2
    Write-Host "OBS closed." -ForegroundColor Green
    Write-Host ""
}

# Copy DLL
$SourceDLL = "D:\Coding\obs-plugins\obs_scene_tree_view\build_qt683\RelWithDebInfo\obs_scene_tree_view.dll"
$TargetDLL = "C:\Program Files\obs-studio\obs-plugins\64bit\obs_scene_tree_view.dll"

Write-Host "Copying DLL..." -ForegroundColor Yellow
Copy-Item $SourceDLL $TargetDLL -Force
Write-Host "DLL copied successfully!" -ForegroundColor Green
Write-Host ""

# Restart OBS
Write-Host "Starting OBS Studio..." -ForegroundColor Yellow
Start-Process "C:\Program Files\obs-studio\bin\64bit\obs64.exe"
Write-Host "OBS started!" -ForegroundColor Green
Write-Host ""
Write-Host "Check View -> Docks -> Scene Tree View to enable the dock." -ForegroundColor Cyan

