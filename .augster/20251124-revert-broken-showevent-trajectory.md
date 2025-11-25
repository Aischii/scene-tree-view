# Mission: Revert Broken showEvent() Approach and Restore Working Code

## Analysis

The showEvent() approach is fundamentally flawed because:
1. We store a reference to the widget
2. We detach it and pass it to OBS via `obs_frontend_add_dock_by_id()`
3. OBS takes ownership and wraps it in its own QDockWidget
4. When we try to re-attach it in showEvent(), we're trying to steal it back from OBS
5. This creates a parent-child conflict and the widget doesn't render

The log shows showEvent IS being called and trying to restore, but it's not working because the widget is already owned by OBS's dock wrapper.

## Solution

Revert ALL showEvent() changes and go back to the ORIGINAL working code that was functioning before we started trying to fix the hidden tab issue.

The original code worked in most cases. The hidden tab issue is a Qt limitation that we should document rather than try to work around with a broken solution.

## Phase 1: Revert Changes

### 1.1. Remove showEvent from Header

Remove the showEvent() declaration and _detached_content member variable from the header file.

**Why:** These were added for the broken approach.

**How:**
1. Open `obs_scene_tree_view/obs_scene_tree_view.h`
2. Remove the `protected:` section with `showEvent()` declaration
3. Remove `QWidget* _detached_content = nullptr;` from private members

**Risks:** None - reverting to known working state.

**Acceptance Criteria:** Header matches original structure.

**Verification:** Build succeeds.

---

### 1.2. Remove showEvent Implementation

Remove the showEvent() method implementation from the .cpp file.

**Why:** This method doesn't work as intended.

**How:**
1. Open `obs_scene_tree_view/obs_scene_tree_view.cpp`
2. Remove the entire `showEvent()` method (lines ~207-217)

**Risks:** None - reverting.

**Acceptance Criteria:** Method is removed.

**Verification:** Build succeeds.

---

### 1.3. Remove Reference Storage from Constructor

Remove the line that stores `_detached_content` in the constructor.

**Why:** No longer needed.

**How:**
1. Open `obs_scene_tree_view/obs_scene_tree_view.cpp`
2. Remove lines 200-202 (the comment and `this->_detached_content = this->widget();`)

**Risks:** None - reverting.

**Acceptance Criteria:** Constructor matches original.

**Verification:** Build succeeds.

---

## Phase 2: Build and Verify

### 2.1. Clean Build

Rebuild the plugin to ensure all changes are reverted.

**Why:** Confirm the code compiles and works.

**How:** Run clean build command.

**Risks:** None.

**Acceptance Criteria:** Build succeeds.

**Verification:** DLL is updated.

---

## Summary

This reverts the broken showEvent() approach and restores the plugin to its previous working state. The hidden tab issue is a Qt framework limitation that cannot be easily worked around without breaking the normal functionality.

**Recommendation:** Document the hidden tab limitation as a known issue rather than trying to fix it with a broken workaround.
