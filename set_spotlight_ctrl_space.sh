#!/usr/bin/env bash
set -euo pipefail

DOMAIN="com.apple.symbolichotkeys"
PREF_DIR="$HOME/Library/Preferences"
PREF_PLIST="$PREF_DIR/com.apple.symbolichotkeys.plist"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_PLIST="$PREF_PLIST.backup-$TS"

echo "▶ 현재 설정 파일을 같은 위치에 백업합니다..."
echo "▶ 백업 파일: $BACKUP_PLIST"

if [[ -f "$PREF_PLIST" ]]; then
  cp -p "$PREF_PLIST" "$BACKUP_PLIST"
else
  echo "⚠ 기존 설정 파일이 없습니다. (최초 생성 상태일 수 있음)"
fi

echo "▶ Spotlight(64번)를 Ctrl+Space로 설정합니다..."

# Ctrl+Space = (32, 49, 262144)
defaults write "$DOMAIN" AppleSymbolicHotKeys -dict-add 64 \
"{ enabled = 1; value = { parameters = (32, 49, 262144); type = 'standard'; }; }"

killall cfprefsd >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

echo ""
echo "✅ 설정이 완료되었습니다."
echo "👉 적용되지 않으면 로그아웃 후 다시 로그인하거나 재부팅하세요."
echo "👉 백업 파일 위치: $BACKUP_PLIST"
