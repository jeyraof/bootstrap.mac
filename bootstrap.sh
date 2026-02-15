#!/usr/bin/env bash
set -euo pipefail

TMPDIR="$(mktemp -d)"
ARCHIVE_FILE="$TMPDIR/repo.tar.gz"
REPO_TARBALL_URL="${BOOTSTRAP_MAC_TARBALL_URL:-https://github.com/jeyraof/bootstrap.mac/archive/refs/heads/main.tar.gz}"

cleanup() {
  rm -rf "$TMPDIR"
}

trap cleanup EXIT INT TERM

if ! command -v curl >/dev/null 2>&1; then
  echo "curl이 필요합니다: curl을 설치한 뒤 다시 실행하세요." >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "tar가 필요합니다: tar를 설치한 뒤 다시 실행하세요." >&2
  exit 1
fi

if ! command -v find >/dev/null 2>&1; then
  echo "find가 필요합니다: find를 설치한 뒤 다시 실행하세요." >&2
  exit 1
fi

if [[ "$#" -gt 0 ]]; then
  echo "지원되지 않는 인자를 전달했습니다." >&2
  exit 1
fi

curl -fsSL "$REPO_TARBALL_URL" -o "$ARCHIVE_FILE"
tar -xzf "$ARCHIVE_FILE" -C "$TMPDIR"

REPO_DIR="$(find "$TMPDIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
if [[ -z "$REPO_DIR" ]]; then
  echo "실행 디렉토리를 찾지 못했습니다." >&2
  exit 1
fi

RUN_SCRIPT="$REPO_DIR/run.sh"
if [[ ! -f "$RUN_SCRIPT" ]]; then
  echo "run.sh를 찾지 못했습니다: $RUN_SCRIPT" >&2
  exit 1
fi

chmod +x "$RUN_SCRIPT"

# run.sh는 TTY 기반이라 /dev/tty를 통해 상호작용을 계속 사용합니다.
if [[ -r /dev/tty && -w /dev/tty ]]; then
  "$RUN_SCRIPT" "$@" < /dev/tty > /dev/tty 2>&1
else
  "$RUN_SCRIPT" "$@"
fi
