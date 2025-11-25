# Scene Tree View Plugin - Fixed Version Installation

## What Was Fixed

The Scene Tree View dock was appearing **empty** (only title bar visible, no content) after OBS restart when:
- Docked to the **left of the video preview/viewer area**, OR
- **Tabbed/combined with another dock**

**Root Cause:** Double QDockWidget wrapping caused by the .ui file defining a QDockWidget inside the C++ QDockWidget class, leading to widget detachment that broke state restoration.

**Fix Applied:** 
1. Changed `.ui` file root widget from `QDockWidget` to `QWidget`
2. Updated registration to use `obs_frontend_add_custom_qdock` instead of widget detachment pattern
3. Eliminated Qt warnings about invalid dock area and layout issues

**Result:** Dock content now displays correctly in **ALL** positions after OBS restart.

---

## Quick Installation (Automated)

### Option 1: PowerShell Script (Recommended)

Run this command in PowerShell **as Administrator**:

```powershell
cd D:\Coding\obs-plugins\obs_scene_tree_view
.\scripts\install-fixed-plugin.ps1
```

The script will:
- ✅ Check if OBS is running (and offer to close it)
- ✅ Backup your existing plugin DLL
- ✅ Copy the fixed DLL to OBS
- ✅ Provide next steps for testing

---

## Manual Installation

### Step 1: Close OBS Studio

**Important:** OBS must be completely closed before installing the plugin.

```powershell
# Check if OBS is running
Get-Process -Name "obs64" -ErrorAction SilentlyContinue

# If running, close it
Stop-Process -Name "obs64" -Force
```

### Step 2: Copy the Fixed DLL

**Source:** `D:\Coding\obs-plugins\obs_scene_tree_view\build_qt683\RelWithDebInfo\obs_scene_tree_view.dll`  
**Target:** `C:\Program Files\obs-studio\obs-plugins\64bit\obs_scene_tree_view.dll`

```powershell
# Backup existing DLL (optional but recommended)
Copy-Item "C:\Program Files\obs-studio\obs-plugins\64bit\obs_scene_tree_view.dll" `
          "C:\Program Files\obs-studio\obs-plugins\64bit\obs_scene_tree_view.dll.backup" `
          -Force

# Install fixed DLL
Copy-Item "D:\Coding\obs-plugins\obs_scene_tree_view\build_qt683\RelWithDebInfo\obs_scene_tree_view.dll" `
          "C:\Program Files\obs-studio\obs-plugins\64bit\obs_scene_tree_view.dll" `
          -Force
```

### Step 3: Launch OBS Studio

Start OBS Studio normally.

### Step 4: Enable the Dock

1. Go to **View → Docks → Scene Tree View** (check it)
2. If the dock doesn't appear, try **View → Docks → Reset UI**, then re-enable it

---

## Testing the Fix

### Test 1: Left Dock Position

1. Drag **Scene Tree View** to the **left of the video preview**
2. Verify the content is visible (tree view + toolbar buttons)
3. **Close OBS completely**
4. **Reopen OBS**
5. ✅ **Expected:** Dock content is still visible and functional

### Test 2: Tabbed Configuration

1. Drag **Scene Tree View** onto another dock (e.g., **Sources**) to create tabs
2. Verify both docks show as tabs and content is visible
3. **Close OBS completely**
4. **Reopen OBS**
5. ✅ **Expected:** Both docks are visible in tabs, content displays correctly

### Test 3: Other Positions

Test these positions to ensure nothing broke:
- **Bottom dock area**
- **Right dock area**
- **Floating** (undocked window)

All should work correctly.

### Test 4: Verify Logs

1. Open OBS logs: **Help → Log Files → View Current Log**
2. Search for `SceneTreeView`
3. ✅ **Expected to see:**
   ```
   [SceneTreeView] loaded version 0.1.9
   [SceneTreeView] registered via add_dock_by_id
   ```
4. ✅ **Should NOT see:**
   - `QMainWindow::addDockWidget: invalid 'area' argument`
   - `QDockWidgetLayout::addItem(): please use QDockWidgetLayout::setWidget()`

---

## Troubleshooting

### Issue: "Access Denied" when copying DLL

**Solution:** Run PowerShell **as Administrator**

```powershell
# Right-click PowerShell → Run as Administrator
```

### Issue: Dock still appears empty

**Possible causes:**
1. OBS was not fully closed before installing
2. Wrong DLL was copied
3. OBS is loading an older version from a different location

**Solutions:**
1. Ensure OBS is completely closed (check Task Manager)
2. Verify the DLL timestamp matches the build time
3. Check for duplicate plugins in `%APPDATA%\obs-studio\plugins\` and remove them

### Issue: Dock doesn't appear in Docks menu

**Solution:**
1. **View → Docks → Reset UI**
2. Re-enable **View → Docks → Scene Tree View**

---

## Build Information

- **Plugin Version:** 0.1.9 (with visibility and sizing fixes)
- **Build Date:** 2025-11-24
- **OBS Version:** 32.x
- **Qt Version:** 6.8.3
- **Platform:** Windows x64
- **Compiler:** MSVC (Visual Studio 2022)
- **Build Config:** RelWithDebInfo
- **DLL Size:** ~268 KB

---

## Technical Details

For developers interested in the technical details of the fix, see:
- **`docs/FIX_EMPTY_DOCK_ISSUE.md`** - Comprehensive technical explanation
- **Git diff** - Review the exact code changes made

### Files Modified

1. **`forms/scene_tree_view.ui`**
   - Changed root widget from `QDockWidget` to `QWidget`
   - Removed nested `stvContents` wrapper

2. **`obs_scene_tree_view/obs_scene_tree_view.cpp`**
   - Changed registration from `obs_frontend_add_dock_by_id` to `obs_frontend_add_custom_qdock`
   - Removed widget detachment pattern
   - Updated retry logic in `FINISHED_LOADING` event

---

## Support

If you encounter any issues with the fixed plugin:

1. Check the OBS logs for errors
2. Review `docs/FIX_EMPTY_DOCK_ISSUE.md` for technical details
3. Verify you're using OBS Studio 32.x
4. Ensure no other versions of the plugin are installed

---

## Next Steps After Installation

1. ✅ Install the fixed DLL
2. ✅ Test in all dock positions
3. ✅ Verify logs show correct registration
4. ✅ Confirm no Qt warnings appear
5. ✅ Use the plugin normally!

**Enjoy your fully functional Scene Tree View dock!** 🎉

