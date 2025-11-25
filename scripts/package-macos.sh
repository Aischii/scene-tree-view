#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR=${1:-build}
OUT_DIR=${2:-dist}

STAGE="${OUT_DIR}/obs-scene-tree-view-macos"
PLUGIN_DIR="${STAGE}/Library/Application Support/obs-studio/plugins/obs_scene_tree_view.plugin/Contents/MacOS"
LOCALE_DIR="${STAGE}/Library/Application Support/obs-studio/plugins/obs_scene_tree_view/locale"

rm -rf "${STAGE}" && mkdir -p "${PLUGIN_DIR}" "${LOCALE_DIR}"

# Locate built .dylib (fallback to .so)
PLUGIN_BIN=$(find "${BUILD_DIR}" -type f \( -name "obs_scene_tree_view.dylib" -o -name "obs_scene_tree_view.so" \) | head -n 1 || true)
if [[ -z "${PLUGIN_BIN}" ]]; then
  echo "ERROR: obs_scene_tree_view.dylib (or .so) not found under ${BUILD_DIR}" >&2
  exit 1
fi

cp -v "${PLUGIN_BIN}" "${PLUGIN_DIR}/obs_scene_tree_view"

# Locales
cp -v data/locale/*.ini "${LOCALE_DIR}/"

# INSTALL instructions
cat > "${STAGE}/INSTALL.txt" << 'EOF'
Installation Instructions for macOS (System-Level)
=================================================

1) Close OBS Studio completely.
2) Extract this archive.
3) Copy the "Library" folder to the root of your disk (/) and allow merge.
   - Or manually copy to:
     /Library/Application Support/obs-studio/plugins/obs_scene_tree_view.plugin/Contents/MacOS/obs_scene_tree_view
     /Library/Application Support/obs-studio/plugins/obs_scene_tree_view/locale/*.ini
4) Start OBS Studio.
5) Enable the dock via: View 2 Docks 2 Scene Tree View (Reset UI if needed).

IMPORTANT: macOS Gatekeeper Bypass (Unsigned Binary)
====================================================
This plugin is NOT code-signed. macOS Gatekeeper will block it on first launch.
You MUST bypass Gatekeeper using ONE of these methods:

Method 1 (Recommended - Right-Click):
  1. Right-click the plugin file in Finder
  2. Select "Open"
  3. Click "Open" in the security dialog
  4. The plugin will now work permanently

Method 2 (Terminal - xattr):
  1. Open Terminal
  2. Run: xattr -cr "/Library/Application Support/obs-studio/plugins/obs_scene_tree_view.plugin"
  3. Restart OBS Studio

Method 3 (System Settings):
  1. Try to launch OBS with the plugin
  2. Open System Settings -> Privacy & Security
  3. Scroll to "Security" section
  4. Click "Open Anyway" next to the blocked plugin warning
  5. Restart OBS Studio

Notes:
- This is a system-level install and may require administrator privileges.
- OBS 32.x is required.
- Universal binary (x86_64 + arm64) for Intel and Apple Silicon Macs.
EOF


# Create ZIP
mkdir -p "${OUT_DIR}"
ZIP_PATH="${OUT_DIR}/obs-scene-tree-view-macos.zip"
(cd "${OUT_DIR}" && zip -r "$(basename "${ZIP_PATH}")" "$(basename "${STAGE}")")

# Generate SHA256 checksum
shasum -a 256 "${ZIP_PATH}" | awk '{print $1 "  " $2}' > "${ZIP_PATH}.sha256"

echo "Packaged: ${ZIP_PATH}"
echo "Checksum: ${ZIP_PATH}.sha256"

