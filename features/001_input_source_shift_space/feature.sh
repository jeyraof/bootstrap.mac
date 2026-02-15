#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_LABEL="입력 소스 전환 Shift + Space 적용"
FEATURE_DESCRIPTION_PATH="$SCRIPT_DIR/description"
FEATURE_APPLY_SCRIPT="$SCRIPT_DIR/set.sh"
FEATURE_RESET_SCRIPT="$SCRIPT_DIR/reset.sh"
FEATURE_ENABLED=1
