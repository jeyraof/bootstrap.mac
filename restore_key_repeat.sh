#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=backup_common.sh
source "$SCRIPT_DIR/backup_common.sh"

BACKUP_FILE="$(original_path "keyrepeat" "env")"

usage() {
  echo "사용 방법:"
  echo "$0"
}

if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi

if [[ $# -eq 1 ]]; then
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "❌ 이 스크립트는 인자를 지원하지 않습니다: $1" >&2
      usage
      exit 1
      ;;
  esac
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "❌ defaults(original) 백업이 없습니다. 먼저 set 스크립트를 실행하세요." >&2
  echo "   expected: $BACKUP_FILE" >&2
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
  elif [[ "$value" =~ ^-?[0-9]+$ ]]; then
    defaults write -g "$key" -int "$value"
    echo "  - $key: $value 로 복원"
  else
    echo "❌ 백업 파일 형식이 올바르지 않습니다: $BACKUP_FILE ($key=$value)" >&2
    return 1
  fi
}

INITIAL_KEY_REPEAT="$(get_value InitialKeyRepeat)"
KEY_REPEAT="$(get_value KeyRepeat)"

if [[ -z "$INITIAL_KEY_REPEAT" && -z "$KEY_REPEAT" ]]; then
  echo "❌ 백업 파일 형식이 올바르지 않습니다: $BACKUP_FILE"
  exit 1
fi

echo "▶ defaults(original) 백업으로 key repeat 설정을 복원합니다..."
restore_key InitialKeyRepeat "$INITIAL_KEY_REPEAT"
restore_key KeyRepeat "$KEY_REPEAT"

killall cfprefsd >/dev/null 2>&1 || true

echo "✅ 복원이 완료되었습니다."
echo "👉 적용이 늦으면 로그아웃/로그인을 진행하세요."
