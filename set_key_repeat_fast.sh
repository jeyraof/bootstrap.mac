#!/usr/bin/env bash
set -euo pipefail

TARGET_INITIAL_KEY_REPEAT=15
TARGET_KEY_REPEAT=1

PREF_DIR="$HOME/Library/Preferences"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="$PREF_DIR/.GlobalPreferences.keyrepeat.backup-$TS"

read_or_unset() {
  local key="$1"
  defaults read -g "$key" 2>/dev/null || echo "UNSET"
}

CURRENT_INITIAL_KEY_REPEAT="$(read_or_unset InitialKeyRepeat)"
CURRENT_KEY_REPEAT="$(read_or_unset KeyRepeat)"

cat >"$BACKUP_FILE" <<EOF
# key repeat backup
# created_at=$TS
InitialKeyRepeat=$CURRENT_INITIAL_KEY_REPEAT
KeyRepeat=$CURRENT_KEY_REPEAT
EOF

echo "▶ 현재 key repeat 설정을 백업합니다..."
echo "▶ 백업 파일: $BACKUP_FILE"
echo "  - InitialKeyRepeat=$CURRENT_INITIAL_KEY_REPEAT"
echo "  - KeyRepeat=$CURRENT_KEY_REPEAT"

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
