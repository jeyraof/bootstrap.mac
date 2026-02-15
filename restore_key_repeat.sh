#!/usr/bin/env bash
set -euo pipefail

BACKUP_FILE="${1:-}"

if [[ -z "$BACKUP_FILE" || ! -f "$BACKUP_FILE" ]]; then
  echo "사용 방법:"
  echo "$0 백업파일경로"
  echo "예시:"
  echo "$0 ~/Library/Preferences/.GlobalPreferences.keyrepeat.backup-YYYYMMDD-HHMMSS"
  exit 1
fi

get_value() {
  local key="$1"
  awk -F= -v target="$key" '$1 == target { print $2 }' "$BACKUP_FILE"
}

restore_key() {
  local key="$1"
  local value="$2"

  if [[ "$value" == "UNSET" || -z "$value" ]]; then
    defaults delete -g "$key" >/dev/null 2>&1 || true
    echo "  - $key: 기본값(미설정)으로 복원"
  else
    defaults write -g "$key" -int "$value"
    echo "  - $key: $value 로 복원"
  fi
}

INITIAL_KEY_REPEAT="$(get_value InitialKeyRepeat)"
KEY_REPEAT="$(get_value KeyRepeat)"

if [[ -z "$INITIAL_KEY_REPEAT" && -z "$KEY_REPEAT" ]]; then
  echo "❌ 백업 파일 형식이 올바르지 않습니다: $BACKUP_FILE"
  exit 1
fi

echo "▶ 백업 파일로 key repeat 설정을 복원합니다..."
restore_key InitialKeyRepeat "$INITIAL_KEY_REPEAT"
restore_key KeyRepeat "$KEY_REPEAT"

killall cfprefsd >/dev/null 2>&1 || true

echo "✅ 복원이 완료되었습니다."
echo "👉 적용이 늦으면 로그아웃/로그인을 진행하세요."
