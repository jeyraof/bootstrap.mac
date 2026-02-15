#!/usr/bin/env bash
set -euo pipefail

PREF_PLIST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
BACKUP_PLIST="${1:-}"

if [[ -z "$BACKUP_PLIST" || ! -f "$BACKUP_PLIST" ]]; then
  echo "사용 방법:"
  echo "$0 백업파일경로"
  echo "예시:"
  echo "$0 ~/Library/Preferences/com.apple.symbolichotkeys.plist.backup-YYYYMMDD-HHMMSS"
  exit 1
fi

echo "▶ 백업 파일로 복원합니다..."
cp -p "$BACKUP_PLIST" "$PREF_PLIST"

killall cfprefsd >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

echo "✅ 복원이 완료되었습니다."
echo "👉 필요하면 로그아웃하거나 재부팅하세요."

