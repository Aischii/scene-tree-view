# Mission: Implement showEvent() Workaround for Hidden Tab Content Restoration

## Phase 1: Implementation

### 1.1. Add Member Variable and showEvent Override to Header

**What:** Add a private member variable `QWidget* _detached_content` to store the reference to the detached widget, and add a protected `showEvent()` override declaration.

**Why:** We need to store the widget reference so we can re-attach it when the dock becomes visible after being in a hidden tab. Qt's state restoration fails for hidden tabs when widgets are detached, so we implement our own restoration logic.

**How:**
1. Open `obs_scene_tree_view/obs_scene_tree_view.h`
2. In the `protected:` section (after line 28, before `protected slots:`), add:
   ```cpp
   protected:
       void showEvent(QShowEvent* event) override;
   ```
3. In the `private:` section (after line 63, near `Ui::STVDock _stv_dock;`), add:
   ```cpp
   QWidget* _detached_content = nullptr;
   ```

**Step-by-step implementation:**
- Locate the protected section (currently only has destructor)
- Add showEvent declaration
- Locate the private member variables section
- Add _detached_content member variable initialized to nullptr

**Risks:** None - this is a non-breaking addition. The showEvent will only activate when content is missing.

**Acceptance Criteria:** 
- Header file compiles without errors
- showEvent is properly declared as protected override
- _detached_content member variable is declared as private

**Verification Strategy:** 
- Build the project and check for compilation errors
- Use diagnostics tool to verify no syntax errors

---

### 1.2. Implement showEvent Method

**What:** Implement the `showEvent()` method in the .cpp file that checks if the widget content is missing and restores it if needed.

**Why:** This is the core workaround. When the dock becomes visible (e.g., user switches to the hidden tab), we check if Qt failed to restore the content and manually re-attach it.

**How:**
1. Open `obs_scene_tree_view/obs_scene_tree_view.cpp`
2. Add the implementation after the destructor (around line 200-220)
3. Implementation logic:
   ```cpp
   void ObsSceneTreeView::showEvent(QShowEvent* event)
   {
       QDockWidget::showEvent(event);  // Call base class implementation first
       
       // Check if content was lost during state restoration (hidden tab issue)
       if (!widget() && _detached_content) {
           blog(LOG_INFO, "[%s] showEvent: restoring lost content (hidden tab recovery)", 
                obs_module_name());
           setWidget(_detached_content);
       }
   }
   ```

**Step-by-step implementation:**
- Find a good location after the destructor
- Add the method implementation
- Call base class showEvent first (important for Qt event chain)
- Check if widget() is null AND we have a stored reference
- If both conditions true, re-attach the content
- Add logging for debugging

**Risks:** 
- Potential issue: If OBS or Qt tries to delete the widget, we might have a dangling pointer
- Mitigation: The widget is managed by Qt's parent-child system, so it won't be deleted while OBS holds it
- Potential issue: Re-attaching might cause layout issues
- Mitigation: Qt handles re-parenting gracefully, and this only happens when content is missing

**Acceptance Criteria:**
- Method compiles without errors
- Calls base class implementation
- Only restores content when both conditions are met
- Includes logging for debugging

**Verification Strategy:**
- Build succeeds
- Test by placing dock in hidden tab, closing OBS, reopening
- Check OBS logs for "hidden tab recovery" message when switching to the tab

---

### 1.3. Store Content Reference in Constructor

**What:** Modify the constructor to store the detached widget reference in `_detached_content` before passing it to OBS.

**Why:** We need to keep the reference so showEvent can re-attach it later.

**How:**
1. Open `obs_scene_tree_view/obs_scene_tree_view.cpp`
2. Find the constructor section where `dock->widget()` is called (line 94)
3. After getting the contents but before detaching, store the reference:
   ```cpp
   QWidget *contents = dock->widget();
   bool added = false;
   if (contents) {
       // Store reference for potential re-attachment in showEvent
       dock->_detached_content = contents;
       // Detach contents from our QDockWidget shell so OBS can reparent it
       dock->setWidget(nullptr);
       obs_frontend_add_dock_by_id("obs_scene_tree_view",
           obs_module_text("SceneTreeView.Title"), contents);
       blog(LOG_INFO, "[%s] registered via add_dock_by_id", obs_module_name());
       added = true;
   }
   ```

**Step-by-step implementation:**
- Locate line 94 where `QWidget *contents = dock->widget();` is called
- After this line, before `dock->setWidget(nullptr);`, add `dock->_detached_content = contents;`
- This stores the reference before we detach it

**Risks:** None - just storing a pointer that's already being used.

**Acceptance Criteria:**
- Reference is stored before detachment
- Code compiles without errors
- No change to existing logic flow

**Verification Strategy:**
- Code review confirms proper storage order
- Build succeeds

---

### 1.4. Store Content Reference in Retry Logic

**What:** Also store the content reference in the retry logic within `ObsFrontendEvent()` to ensure consistency.

**Why:** The retry logic (lines 610-625) also detaches the widget, so it needs to store the reference too.

**How:**
1. Open `obs_scene_tree_view/obs_scene_tree_view.cpp`
2. Find the retry logic in `ObsFrontendEvent()` (around line 610-625)
3. Add the same storage logic:
   ```cpp
   if (!g_stv_added && g_stv_dock) {
       QWidget *contents = g_stv_dock->widget();
       bool added = false;
       if (contents) {
           // Store reference for potential re-attachment in showEvent
           g_stv_dock->_detached_content = contents;
           // Detach contents so OBS can reparent
           g_stv_dock->setWidget(nullptr);
           obs_frontend_add_dock_by_id("obs_scene_tree_view",
               obs_module_text("SceneTreeView.Title"), contents);
           blog(LOG_INFO, "[%s] retry add_dock_by_id succeeded", obs_module_name());
           added = true;
       }
   }
   ```

**Step-by-step implementation:**
- Locate the retry logic section
- Find where `QWidget *contents = g_stv_dock->widget();` is called
- Add `g_stv_dock->_detached_content = contents;` before the detachment

**Risks:** None - maintaining consistency with main registration.

**Acceptance Criteria:**
- Reference is stored in retry path
- Code compiles without errors
- Retry logic maintains same behavior

**Verification Strategy:**
- Code review confirms both paths store the reference
- Build succeeds

---

## Phase 2: Build

### 2.1. Clean Build the Plugin

**What:** Perform a clean build of the plugin using CMake to compile all changes.

**Why:** Ensure the new code is properly compiled into the DLL and ready for testing.

**How:**
1. Run: `cmake --build build_qt683 --config RelWithDebInfo --clean-first`
2. Verify build succeeds with no errors
3. Check DLL timestamp to confirm it was rebuilt
4. Run: `Get-Item "build_qt683\RelWithDebInfo\obs_scene_tree_view.dll" | Select-Object LastWriteTime, Length`

**Step-by-step implementation:**
- Execute clean build command
- Monitor output for errors or warnings
- Verify DLL was updated

**Risks:** 
- Potential compilation errors if syntax is wrong
- Mitigation: Use diagnostics tool before building

**Acceptance Criteria:**
- Build completes successfully
- No compilation errors or warnings
- DLL timestamp is current
- DLL size is reasonable (similar to previous builds)

**Verification Strategy:**
- Check build output for "Build succeeded"
- Verify DLL timestamp matches current time
- Compare DLL size to previous build (should be similar, maybe slightly larger)

---

## Summary

This trajectory implements a workaround for Qt's limitation with hidden tab state restoration. By storing a reference to the detached widget and re-attaching it in `showEvent()`, we ensure the dock always has content when it becomes visible, regardless of whether it was in a hidden tab during OBS shutdown.

The solution is:
- **Non-breaking**: Only activates when content is missing
- **Minimal**: Adds one member variable and one method override
- **Robust**: Handles both initial registration and retry paths
- **Debuggable**: Includes logging to track when recovery occurs

This is the industry-standard workaround for this Qt QDockWidget limitation.
