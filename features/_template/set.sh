#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../../backup_common.sh
source "$REPO_ROOT/backup_common.sh"

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

# TODO: 원본 백업 및 적용 로직을 여기에 구현하세요.
# 예: save_original_once "<target>" "<ext>" "$(basename "$0")" "$REFRESH_ORIGINAL" <writer>

echo "▶ 적용 로직이 아직 구현되지 않았습니다."
echo "   필요한 설정 값을 write 하거나 파일을 수정하는 동작을 추가하세요."
