# Fix for Empty Dock Issue After OBS Restart

## Problem Description

The Scene Tree View dock appeared empty (showing only the title bar with no content) after closing and reopening OBS Studio under specific conditions:

1. **When docked to the left of the video preview/viewer area**, OR
2. **When combined/tabbed with another dock** (where multiple docks share the same space)

The issue did **NOT** occur:
- In other dock positions (bottom, right, floating)
- On a clean OBS installation with only Scene Tree View loaded
- With any other docks (native or third-party)

## Root Cause Analysis

### The Double QDockWidget Wrapping Problem

The plugin had an architectural flaw that created a **nested QDockWidget structure**:

**Before the fix:**
```
ObsSceneTreeView (QDockWidget) ← C++ class inherits from QDockWidget
  └─ STVDock (QDockWidget) ← .ui file defined this as QDockWidget
      └─ stvContents (QWidget) ← Actual content widget
```

**What was happening:**
1. `ObsSceneTreeView` class inherited from `QDockWidget`
2. The .ui file (`forms/scene_tree_view.ui`) **also** defined its root widget as `QDockWidget`
3. When `setupUi(this)` was called, Qt created a QDockWidget inside a QDockWidget
4. The code then extracted the innermost widget via `dock->widget()` and detached it with `setWidget(nullptr)`
5. Only the detached content widget was passed to `obs_frontend_add_dock_by_id`

**Why this caused the empty dock:**
- The detached widget lost all QDockWidget metadata (geometry hints, dock properties, parent relationships)
- When OBS tried to restore dock state from settings, it couldn't properly reconstruct the dock in complex positions
- Simple dock positions (bottom, right) were more forgiving, but left-of-preview and tabbed configurations require proper QDockWidget structure
- Qt warnings appeared: `QMainWindow::addDockWidget: invalid 'area' argument` and `QDockWidgetLayout::addItem(): please use QDockWidgetLayout::setWidget()`

## The Fix

### Changes Made

#### 1. Modified `forms/scene_tree_view.ui`

**Changed the root widget from `QDockWidget` to `QWidget`:**

```xml
<!-- BEFORE -->
<widget class="QDockWidget" name="STVDock">
  <property name="floating">
   <bool>false</bool>
  </property>
  <property name="windowTitle">
   <string>SceneTreeView.Title</string>
  </property>
  <widget class="QWidget" name="stvContents">
    <!-- content here -->
  </widget>
</widget>

<!-- AFTER -->
<widget class="QWidget" name="STVDock">
  <property name="geometry">
   <!-- geometry here -->
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
    <!-- content directly in layout -->
  </layout>
</widget>
```

**Result:** Eliminated the nested QDockWidget structure. Now `setupUi(this)` sets up the layout directly on the `ObsSceneTreeView` QDockWidget.

#### 2. Modified `obs_scene_tree_view/obs_scene_tree_view.cpp`

**Changed dock registration from widget detachment pattern to direct QDockWidget registration:**

```cpp
// BEFORE (lines 92-107)
QWidget *contents = dock->widget();
if (contents) {
    dock->setWidget(nullptr);  // Detach and orphan the widget
    obs_frontend_add_dock_by_id("obs_scene_tree_view",
        obs_module_text("SceneTreeView.Title"), contents);
    // ...
}

// AFTER (lines 92-98)
bool added = obs_frontend_add_custom_qdock("obs_scene_tree_view", dock);
if (added)
    blog(LOG_INFO, "[%s] registered via add_custom_qdock", obs_module_name());
else
    blog(LOG_WARNING, "[%s] failed to register dock", obs_module_name());
```

**Also updated the retry logic in `FINISHED_LOADING` event (lines 601-609)** to use the same pattern.

**Result:** The entire `ObsSceneTreeView` QDockWidget is now registered with OBS, preserving all dock properties and metadata.

### Why This Fix Works

1. **No more double-wrapping:** The .ui file now defines a simple `QWidget`, not a `QDockWidget`
2. **Proper dock structure:** `ObsSceneTreeView` (QDockWidget) contains the UI layout directly
3. **No widget detachment:** The entire QDockWidget is passed to OBS, maintaining parent-child relationships
4. **State restoration works:** OBS can properly save and restore dock geometry, position, and tab state
5. **Qt warnings eliminated:** No more invalid dock area or layout warnings

## Testing Instructions

### Installation

1. **Close OBS Studio completely**

2. **Copy the built DLL:**
   ```powershell
   Copy-Item "D:\Coding\obs-plugins\obs_scene_tree_view\build_qt683\RelWithDebInfo\obs_scene_tree_view.dll" `
             "C:\Program Files\obs-studio\obs-plugins\64bit\obs_scene_tree_view.dll" -Force
   ```

3. **Locale files are already installed** (no changes needed)

4. **Launch OBS Studio**

### Verification Steps

Test the dock in all problematic positions:

1. **Test Left Dock Position:**
   - Drag Scene Tree View to the left of the video preview
   - Close OBS
   - Reopen OBS
   - ✅ **Expected:** Dock content is visible and functional

2. **Test Tabbed Configuration:**
   - Drag Scene Tree View onto another dock (e.g., Sources) to create tabs
   - Close OBS
   - Reopen OBS
   - ✅ **Expected:** Both docks are visible in tabs, content displays correctly

3. **Test Other Positions:**
   - Test bottom, right, and floating positions
   - ✅ **Expected:** All positions work correctly

4. **Check Logs:**
   - Open OBS logs (Help → Log Files → View Current Log)
   - Search for "SceneTreeView"
   - ✅ **Expected:** See `[SceneTreeView] registered via add_custom_qdock`
   - ✅ **Expected:** No Qt warnings about invalid dock area or layout

## Technical Details

- **OBS Version:** 32.x
- **Qt Version:** 6.8.3
- **Build Configuration:** RelWithDebInfo (Windows x64, MSVC)
- **Plugin Version:** 0.1.5 (with fix applied)

## Files Modified

1. `forms/scene_tree_view.ui` - Changed root widget from QDockWidget to QWidget
2. `obs_scene_tree_view/obs_scene_tree_view.cpp` - Changed registration to use `obs_frontend_add_custom_qdock`

## References

- [Qt QDockWidget Documentation](https://doc.qt.io/qt-6/qdockwidget.html)
- [Stack Overflow: PyQt5 QDockWidget from Designer](https://stackoverflow.com/questions/71709543/pyqt5-using-custom-qdockwidget-from-designer-ui-file)
- [OBS Frontend API Documentation](https://docs.obsproject.com/reference-frontend-api)

