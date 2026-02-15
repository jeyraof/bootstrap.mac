#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=backup_common.sh
source "$SCRIPT_DIR/backup_common.sh"

TARGET="keyrepeat"
EXT="env"
LIST_ONLY=0
SELECT_INDEX=""
BACKUP_FILE=""

usage() {
  echo "사용 방법:"
  echo "$0 [--list]"
  echo "$0 [--select 인덱스]"
  echo "$0 [백업파일경로]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)
      LIST_ONLY=1
      ;;
    --select)
      shift
      if [[ $# -eq 0 ]]; then
        echo "❌ --select 뒤에 인덱스를 입력하세요." >&2
        exit 1
      fi
      SELECT_INDEX="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "❌ 알 수 없는 옵션: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [[ -n "$BACKUP_FILE" ]]; then
        echo "❌ 백업 파일 경로는 하나만 입력할 수 있습니다." >&2
        exit 1
      fi
      BACKUP_FILE="$1"
      ;;
  esac
  shift
done

if [[ -n "$BACKUP_FILE" && -n "$SELECT_INDEX" ]]; then
  echo "❌ 백업 파일 경로 인자와 --select는 함께 사용할 수 없습니다." >&2
  exit 1
fi

if [[ "$LIST_ONLY" -eq 1 ]]; then
  if [[ -n "$BACKUP_FILE" || -n "$SELECT_INDEX" ]]; then
    echo "❌ --list는 다른 인자와 함께 사용할 수 없습니다." >&2
    exit 1
  fi
  echo "index|kind|ts|path"
  list_backups "$TARGET" "$EXT"
  exit 0
fi

if [[ -n "$BACKUP_FILE" ]]; then
  validate_backup_file_exists "$BACKUP_FILE"
elif [[ -n "$SELECT_INDEX" ]]; then
  if ! [[ "$SELECT_INDEX" =~ ^[0-9]+$ ]]; then
    echo "❌ 잘못된 인덱스입니다: $SELECT_INDEX" >&2
    exit 1
  fi
  BACKUP_FILE="$(backup_path_by_index "$TARGET" "$EXT" "$SELECT_INDEX")"
  if [[ -z "$BACKUP_FILE" ]]; then
    echo "❌ 인덱스에 해당하는 백업이 없습니다: $SELECT_INDEX" >&2
    exit 1
  fi
  validate_backup_file_exists "$BACKUP_FILE"
else
  BACKUP_FILE="$(interactive_pick_backup "$TARGET" "$EXT")"
  validate_backup_file_exists "$BACKUP_FILE"
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

echo "▶ 백업 파일로 key repeat 설정을 복원합니다..."
restore_key InitialKeyRepeat "$INITIAL_KEY_REPEAT"
restore_key KeyRepeat "$KEY_REPEAT"

killall cfprefsd >/dev/null 2>&1 || true

echo "✅ 복원이 완료되었습니다."
echo "👉 적용이 늦으면 로그아웃/로그인을 진행하세요."
