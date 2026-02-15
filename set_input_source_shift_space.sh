#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=backup_common.sh
source "$SCRIPT_DIR/backup_common.sh"

DOMAIN="com.apple.symbolichotkeys"
PREF_DIR="$HOME/Library/Preferences"
PREF_PLIST="$PREF_DIR/com.apple.symbolichotkeys.plist"

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

write_symbolichotkeys_backup() {
  local out="$1"
  if [[ -f "$PREF_PLIST" ]]; then
    cp -p "$PREF_PLIST" "$out"
  else
    cat >"$out" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
EOF
  fi
}

save_original_once "symbolichotkeys" "plist" "$(basename "$0")" "$REFRESH_ORIGINAL" write_symbolichotkeys_backup
SNAPSHOT_PATH="$(save_snapshot "symbolichotkeys" "plist" "$(basename "$0")" write_symbolichotkeys_backup)"

echo "▶ snapshot 백업 저장: $SNAPSHOT_PATH"

echo "▶ 60번 (이전 입력 소스)을 비활성화합니다..."
defaults write "$DOMAIN" AppleSymbolicHotKeys -dict-add 60 \
"{ enabled = 0; }"

echo "▶ 61번 (다음 입력 소스)을 Shift+Space로 설정합니다..."

# Shift+Space = (32, 49, 131072)
defaults write "$DOMAIN" AppleSymbolicHotKeys -dict-add 61 \
"{ enabled = 1; value = { parameters = (32, 49, 131072); type = 'standard'; }; }"

# 설정 즉시 반영 시도
killall cfprefsd >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

echo ""
echo "✅ 설정이 완료되었습니다."
echo "👉 적용되지 않으면 로그아웃 후 다시 로그인하거나 재부팅하세요."
echo "👉 백업 루트: $(backup_root)"
