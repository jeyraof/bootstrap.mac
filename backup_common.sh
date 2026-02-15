#!/usr/bin/env bash
set -euo pipefail

backup_root() {
  echo "$HOME/.bootstrap.mac/backups"
}

ts_now() {
  date +%Y%m%d-%H%M%S
}

ensure_target_dirs() {
  local target="$1"
  local root
  root="$(backup_root)"
  mkdir -p "$root/$target" || {
    echo "❌ 백업 디렉터리를 생성하지 못했습니다: $root/$target" >&2
    return 1
  }
}

original_path() {
  local target="$1"
  local ext="$2"
  echo "$(backup_root)/$target/original.$ext"
}

write_meta() {
  local meta_path="$1"
  local kind="$2"
  local target="$3"
  local ts="$4"
  local script_name="$5"

  cat >"$meta_path" <<EOF
kind=$kind
target=$target
created_at=$ts
source_script=$script_name
EOF
}

save_original_once() {
  local target="$1"
  local ext="$2"
  local script_name="$3"
  local refresh_flag="$4"
  local writer_fn="$5"
  local original
  local meta
  local ts

  ensure_target_dirs "$target"
  original="$(original_path "$target" "$ext")"
  meta="$(backup_root)/$target/original.meta"

  if [[ "$refresh_flag" -eq 1 || ! -f "$original" ]]; then
    ts="$(ts_now)"
    "$writer_fn" "$original"
    write_meta "$meta" "original" "$target" "$ts" "$script_name"
    echo "▶ original 백업 저장: $original"
  else
    echo "▶ original 백업 유지: $original"
  fi
}

validate_backup_file_exists() {
  local path="$1"
  if [[ -z "$path" || ! -f "$path" ]]; then
    echo "❌ 백업 파일을 찾을 수 없습니다: $path" >&2
    return 1
  fi
}
