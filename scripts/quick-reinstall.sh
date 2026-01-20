#!/usr/bin/env bash
set -euo pipefail

# Quick reinstall script for Linux: copies built .so into OBS plugin folders for testing
# Usage: ./scripts/quick-reinstall.sh [build_dir]

BUILD_DIR=${1:-build}

PLUGIN_SO=$(find "${BUILD_DIR}" -type f -name "obs_scene_tree_view.so" | head -n 1 || true)
if [[ -z "${PLUGIN_SO}" ]]; then
  echo "ERROR: obs_scene_tree_view.so not found under ${BUILD_DIR}" >&2
  exit 1
fi

echo "Found plugin: ${PLUGIN_SO}"

# Attempt user-level install first
USER_TARGET_DIR="${HOME}/.config/obs-studio/plugins/obs_scene_tree_view"
SYSTEM_TARGET_DIR="/usr/lib/obs-plugins"

mkdir -p "${USER_TARGET_DIR}"
cp -v "${PLUGIN_SO}" "${USER_TARGET_DIR}/"

echo "Copied to user plugins dir: ${USER_TARGET_DIR}"

if [[ $(id -u) -eq 0 ]]; then
  mkdir -p "${SYSTEM_TARGET_DIR}"
  cp -v "${PLUGIN_SO}" "${SYSTEM_TARGET_DIR}/"
  echo "Also copied to system plugins dir: ${SYSTEM_TARGET_DIR}"
else
  echo "To install system-wide, run with sudo to copy to ${SYSTEM_TARGET_DIR}"
fi

echo "Done. Restart OBS Studio to load the new plugin."
