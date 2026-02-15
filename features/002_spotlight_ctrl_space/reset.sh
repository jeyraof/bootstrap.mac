#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../../backup_common.sh
source "$REPO_ROOT/backup_common.sh"

PREF_PLIST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
BACKUP_PLIST="$(original_path "symbolichotkeys" "plist")"

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

if [[ ! -f "$BACKUP_PLIST" ]]; then
  echo "❌ defaults(original) 백업이 없습니다. 먼저 set 스크립트를 실행하세요." >&2
  echo "   expected: $BACKUP_PLIST" >&2
  exit 1
fi

echo "▶ defaults(original) 백업으로 복원합니다..."
cp -p "$BACKUP_PLIST" "$PREF_PLIST"

killall cfprefsd >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

echo "✅ 복원이 완료되었습니다."
echo "👉 필요하면 로그아웃하거나 재부팅하세요."
