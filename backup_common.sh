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
  mkdir -p "$root/$target/snapshots" || {
    echo "❌ 백업 디렉터리를 생성하지 못했습니다: $root/$target" >&2
    return 1
  }
}

original_path() {
  local target="$1"
  local ext="$2"
  echo "$(backup_root)/$target/original.$ext"
}

snapshot_path() {
  local target="$1"
  local ext="$2"
  local ts="$3"
  echo "$(backup_root)/$target/snapshots/$ts.$ext"
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

save_snapshot() {
  local target="$1"
  local ext="$2"
  local script_name="$3"
  local writer_fn="$4"
  local ts
  local snapshot
  local meta

  ensure_target_dirs "$target"
  ts="$(ts_now)"
  snapshot="$(snapshot_path "$target" "$ext" "$ts")"
  meta="$(backup_root)/$target/snapshots/$ts.meta"

  "$writer_fn" "$snapshot"
  write_meta "$meta" "snapshot" "$target" "$ts" "$script_name"

  echo "$snapshot"
}

list_backups() {
  local target="$1"
  local ext="$2"
  local original
  local snapshot_dir
  local idx
  local file
  local ts

  original="$(original_path "$target" "$ext")"
  snapshot_dir="$(backup_root)/$target/snapshots"

  if [[ -f "$original" ]]; then
    echo "1|original|original|$original"
  fi

  idx=2
  if [[ -d "$snapshot_dir" ]]; then
    while IFS= read -r file; do
      ts="$(basename "$file")"
      ts="${ts%.$ext}"
      echo "$idx|snapshot|$ts|$file"
      idx=$((idx + 1))
    done < <(find "$snapshot_dir" -maxdepth 1 -type f -name "*.$ext" | sort -r)
  fi
}

backup_path_by_index() {
  local target="$1"
  local ext="$2"
  local index="$3"

  list_backups "$target" "$ext" | awk -F'|' -v idx="$index" '$1 == idx { print $4; exit }'
}

interactive_pick_backup() {
  local target="$1"
  local ext="$2"
  local entries
  local line
  local idx
  local kind
  local ts
  local path
  local selected

  mapfile -t entries < <(list_backups "$target" "$ext")
  if [[ ${#entries[@]} -eq 0 ]]; then
    echo "❌ 복원 가능한 백업이 없습니다. target=$target" >&2
    return 1
  fi

  echo "복원할 백업을 선택하세요:"
  for line in "${entries[@]}"; do
    IFS='|' read -r idx kind ts path <<<"$line"
    echo "  [$idx] $kind @ $ts -> $path"
  done

  read -r -p "번호를 입력하세요: " selected
  path="$(backup_path_by_index "$target" "$ext" "$selected")"
  if [[ -z "$path" ]]; then
    echo "❌ 잘못된 선택입니다: $selected" >&2
    return 1
  fi

  echo "$path"
}

validate_backup_file_exists() {
  local path="$1"
  if [[ -z "$path" || ! -f "$path" ]]; then
    echo "❌ 백업 파일을 찾을 수 없습니다: $path" >&2
    return 1
  fi
}
