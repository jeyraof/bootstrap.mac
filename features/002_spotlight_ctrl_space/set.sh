#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=backup_common.sh
source "$REPO_ROOT/backup_common.sh"

DOMAIN="com.apple.symbolichotkeys"
PREF_DIR="$HOME/Library/Preferences"
PREF_PLIST="$PREF_DIR/com.apple.symbolichotkeys.plist"
PLISTBUDDY="/usr/libexec/PlistBuddy"

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
echo "▶ restore defaults용 original 백업을 확인했습니다."

ensure_pref_file() {
  local plist="$1"
  if [[ ! -f "$plist" ]]; then
    mkdir -p "$(dirname "$plist")"
    cat >"$plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
EOF
  fi
}

set_hotkey_entry() {
  local key="$1"
  local enabled="$2"
  local p0="$3"
  local p1="$4"
  local p2="$5"

  ensure_pref_file "$PREF_PLIST"
  if "$PLISTBUDDY" -c "Print :AppleSymbolicHotKeys:$key" "$PREF_PLIST" >/dev/null 2>&1; then
    "$PLISTBUDDY" -c "Delete :AppleSymbolicHotKeys:$key" "$PREF_PLIST"
  fi
  if ! "$PLISTBUDDY" -c "Print :AppleSymbolicHotKeys" "$PREF_PLIST" >/dev/null 2>&1; then
    "$PLISTBUDDY" -c "Add :AppleSymbolicHotKeys dict" "$PREF_PLIST"
  fi
  "$PLISTBUDDY" -c "Add :AppleSymbolicHotKeys:$key dict" "$PREF_PLIST"
  "$PLISTBUDDY" -c "Add :AppleSymbolicHotKeys:$key:enabled bool $enabled" "$PREF_PLIST"
  "$PLISTBUDDY" -c "Add :AppleSymbolicHotKeys:$key:type string standard" "$PREF_PLIST"
  "$PLISTBUDDY" -c "Add :AppleSymbolicHotKeys:$key:value dict" "$PREF_PLIST"
  "$PLISTBUDDY" -c "Add :AppleSymbolicHotKeys:$key:value:parameters array" "$PREF_PLIST"
  "$PLISTBUDDY" -c "Add :AppleSymbolicHotKeys:$key:value:parameters:0 integer $p0" "$PREF_PLIST"
  "$PLISTBUDDY" -c "Add :AppleSymbolicHotKeys:$key:value:parameters:1 integer $p1" "$PREF_PLIST"
  "$PLISTBUDDY" -c "Add :AppleSymbolicHotKeys:$key:value:parameters:2 integer $p2" "$PREF_PLIST"
}

echo "▶ Spotlight(64번)를 Ctrl+Space로 설정합니다..."
set_hotkey_entry 64 YES 32 49 262144

killall cfprefsd >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

echo ""
echo "✅ 설정이 완료되었습니다."
echo "👉 적용되지 않으면 로그아웃 후 다시 로그인하거나 재부팅하세요."
echo "👉 백업 루트: $(backup_root)"
