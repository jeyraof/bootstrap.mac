#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=backup_common.sh
source "$SCRIPT_DIR/backup_common.sh"

TARGET_INITIAL_KEY_REPEAT=15
TARGET_KEY_REPEAT=1

REFRESH_ORIGINAL=0

usage() {
  echo "사용 방법:"
  echo "$0 [--refresh-original]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --refresh-original)
      REFRESH_ORIGINAL=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

read_or_unset() {
  local key="$1"
  defaults read -g "$key" 2>/dev/null || echo "UNSET"
}

write_keyrepeat_backup() {
  local out="$1"
  local current_initial_key_repeat
  local current_key_repeat
  current_initial_key_repeat="$(read_or_unset InitialKeyRepeat)"
  current_key_repeat="$(read_or_unset KeyRepeat)"
  cat >"$out" <<EOF
InitialKeyRepeat=$current_initial_key_repeat
KeyRepeat=$current_key_repeat
EOF
}

save_original_once "keyrepeat" "env" "$(basename "$0")" "$REFRESH_ORIGINAL" write_keyrepeat_backup
SNAPSHOT_PATH="$(save_snapshot "keyrepeat" "env" "$(basename "$0")" write_keyrepeat_backup)"

echo "▶ snapshot 백업 저장: $SNAPSHOT_PATH"
echo "▶ 현재값:"
echo "  - InitialKeyRepeat=$(read_or_unset InitialKeyRepeat)"
echo "  - KeyRepeat=$(read_or_unset KeyRepeat)"

echo "▶ key repeat 설정을 적용합니다..."
defaults write -g InitialKeyRepeat -int "$TARGET_INITIAL_KEY_REPEAT"
defaults write -g KeyRepeat -int "$TARGET_KEY_REPEAT"

killall cfprefsd >/dev/null 2>&1 || true

echo ""
echo "✅ 설정이 완료되었습니다."
echo "  - InitialKeyRepeat=$TARGET_INITIAL_KEY_REPEAT"
echo "  - KeyRepeat=$TARGET_KEY_REPEAT"
echo "👉 적용이 늦으면 로그아웃/로그인을 진행하세요."
echo "👉 복원은 restore_key_repeat.sh를 사용하세요."
