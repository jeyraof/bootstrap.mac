#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=backup_common.sh
source "$SCRIPT_DIR/backup_common.sh"

PREF_PLIST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
TARGET="symbolichotkeys"
EXT="plist"
LIST_ONLY=0
SELECT_INDEX=""
BACKUP_PLIST=""

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
      if [[ -n "$BACKUP_PLIST" ]]; then
        echo "❌ 백업 파일 경로는 하나만 입력할 수 있습니다." >&2
        exit 1
      fi
      BACKUP_PLIST="$1"
      ;;
  esac
  shift
done

if [[ -n "$BACKUP_PLIST" && -n "$SELECT_INDEX" ]]; then
  echo "❌ 백업 파일 경로 인자와 --select는 함께 사용할 수 없습니다." >&2
  exit 1
fi

if [[ "$LIST_ONLY" -eq 1 ]]; then
  if [[ -n "$BACKUP_PLIST" || -n "$SELECT_INDEX" ]]; then
    echo "❌ --list는 다른 인자와 함께 사용할 수 없습니다." >&2
    exit 1
  fi
  echo "index|kind|ts|path"
  list_backups "$TARGET" "$EXT"
  exit 0
fi

if [[ -n "$BACKUP_PLIST" ]]; then
  validate_backup_file_exists "$BACKUP_PLIST"
elif [[ -n "$SELECT_INDEX" ]]; then
  if ! [[ "$SELECT_INDEX" =~ ^[0-9]+$ ]]; then
    echo "❌ 잘못된 인덱스입니다: $SELECT_INDEX" >&2
    exit 1
  fi
  BACKUP_PLIST="$(backup_path_by_index "$TARGET" "$EXT" "$SELECT_INDEX")"
  if [[ -z "$BACKUP_PLIST" ]]; then
    echo "❌ 인덱스에 해당하는 백업이 없습니다: $SELECT_INDEX" >&2
    exit 1
  fi
  validate_backup_file_exists "$BACKUP_PLIST"
else
  BACKUP_PLIST="$(interactive_pick_backup "$TARGET" "$EXT")"
  validate_backup_file_exists "$BACKUP_PLIST"
fi

echo "▶ 백업 파일로 복원합니다..."
cp -p "$BACKUP_PLIST" "$PREF_PLIST"

killall cfprefsd >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

echo "✅ 복원이 완료되었습니다."
echo "👉 필요하면 로그아웃하거나 재부팅하세요."
