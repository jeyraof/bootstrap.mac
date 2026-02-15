#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 고유 ID (예: 004_example)
FEATURE_ID="004_example"

# 메뉴에 표시될 라벨
FEATURE_LABEL="새 기능"

# 설명 파일 경로
FEATURE_DESCRIPTION_PATH="$SCRIPT_DIR/description"

# 적용/복원 스크립트 경로
FEATURE_APPLY_SCRIPT="$SCRIPT_DIR/set.sh"
FEATURE_RESET_SCRIPT="$SCRIPT_DIR/reset.sh"

# 0으로 두면 메뉴에서 숨김
FEATURE_ENABLED=1
