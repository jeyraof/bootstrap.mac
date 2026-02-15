#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../../backup_common.sh
source "$REPO_ROOT/backup_common.sh"

# TODO: 복원 대상 경로/백업 키를 정의하세요.

echo "▶ 복원 로직이 아직 구현되지 않았습니다."
echo "   백업을 읽어 기존 상태를 복원하는 동작을 추가하세요."
