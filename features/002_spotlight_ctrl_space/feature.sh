#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FEATURE_ID="002_spotlight_ctrl_space"
FEATURE_LABEL="Spotlight Ctrl + Space 적용"
FEATURE_DESCRIPTION_PATH="$SCRIPT_DIR/description"
FEATURE_APPLY_SCRIPT="$SCRIPT_DIR/set.sh"
FEATURE_RESET_SCRIPT="$SCRIPT_DIR/reset.sh"
FEATURE_ENABLED=1
