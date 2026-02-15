#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURES_DIR="$SCRIPT_DIR/features"
BACKUP_ROOT="$HOME/.bootstrap.mac/backups"

MODE="apply_only"
SELECTED=()
ORIG_STTY_SETTINGS=""

FEATURE_IDS=()
FEATURE_LABELS=()
FEATURE_DESCRIPTIONS=()
FEATURE_APPLY_CMDS=()
FEATURE_RESET_CMDS=()

STEP_LABELS=()
STEP_CMDS=()

cleanup() {
  if [[ -n "${ORIG_STTY_SETTINGS}" ]]; then
    stty "$ORIG_STTY_SETTINGS" >/dev/null 2>&1 || true
  fi
  tput cnorm >/dev/null 2>&1 || true
  stty echo >/dev/null 2>&1 || true
}

usage() {
  echo "사용 방법:"
  echo "./run.sh"
}

refresh_ui() {
  clear
}

on_interrupt() {
  cleanup
  echo
  echo "취소되었습니다."
  exit 130
}

trap cleanup EXIT
trap on_interrupt INT TERM

require_tty() {
  if [[ ! -t 0 || ! -t 1 ]]; then
    echo "❌ 이 스크립트는 TTY 환경에서 실행해야 합니다." >&2
    exit 1
  fi
}

load_features() {
  local feature_dir
  local feature_script

  if [[ ! -d "$FEATURES_DIR" ]]; then
    echo "❌ features 디렉토리를 찾을 수 없습니다: $FEATURES_DIR" >&2
    exit 1
  fi

  # features 디렉토리를 이름 정렬 순으로 순회(예: 001_, 002_ ...).
  for feature_dir in "$FEATURES_DIR"/*/; do
    [[ -d "$feature_dir" ]] || continue
    [[ "$feature_dir" == "$FEATURES_DIR/_template/" ]] && continue
    feature_script="$feature_dir/feature.sh"

    if [[ ! -f "$feature_script" ]]; then
      echo "❌ 필수 인터페이스 파일이 없습니다: $feature_script" >&2
      exit 1
    fi
    if [[ ! -r "$feature_script" ]]; then
      echo "❌ feature.sh 읽기 권한이 없습니다: $feature_script" >&2
      exit 1
    fi

    # shellcheck disable=SC1090
    source "$feature_script"

    local id="${FEATURE_ID:-}"
    local label="${FEATURE_LABEL:-}"
    local description_path="${FEATURE_DESCRIPTION_PATH:-$feature_dir/description}"
    local apply_script="${FEATURE_APPLY_SCRIPT:-}"
    local reset_script="${FEATURE_RESET_SCRIPT:-}"
    local enabled="${FEATURE_ENABLED:-1}"

    if [[ "$enabled" != "1" ]]; then
      unset FEATURE_ID FEATURE_LABEL FEATURE_DESCRIPTION_PATH FEATURE_APPLY_SCRIPT FEATURE_RESET_SCRIPT FEATURE_ENABLED FEATURE_REQUIRES_TTY
      continue
    fi

    if [[ -z "$id" || -z "$label" || -z "$apply_script" || -z "$reset_script" ]]; then
      echo "❌ feature.sh에 필수 항목이 누락되었습니다: $feature_script" >&2
      exit 1
    fi

    if [[ ! -x "$apply_script" ]]; then
      echo "❌ 실행 권한이 없습니다: $apply_script" >&2
      echo "   chmod +x \"$apply_script\"" >&2
      exit 1
    fi

    if [[ ! -x "$reset_script" ]]; then
      echo "❌ 실행 권한이 없습니다: $reset_script" >&2
      echo "   chmod +x \"$reset_script\"" >&2
      exit 1
    fi

    if [[ ! -r "$description_path" ]]; then
      echo "❌ 설명 파일을 읽을 수 없습니다: $description_path" >&2
      exit 1
    fi

    FEATURE_IDS+=("$id")
    FEATURE_LABELS+=("$label")
    FEATURE_DESCRIPTIONS+=("$description_path")
    FEATURE_APPLY_CMDS+=("$apply_script")
    FEATURE_RESET_CMDS+=("$reset_script")

    unset FEATURE_ID FEATURE_LABEL FEATURE_DESCRIPTION_PATH FEATURE_APPLY_SCRIPT FEATURE_RESET_SCRIPT FEATURE_ENABLED FEATURE_REQUIRES_TTY
  done

  if [[ ${#FEATURE_IDS[@]} -eq 0 ]]; then
    echo "❌ 활성화된 기능이 없습니다. features 디렉토리를 확인하세요." >&2
    exit 1
  fi

  SELECTED=()
  local i
  for i in "${!FEATURE_LABELS[@]}"; do
    SELECTED+=(0)
  done
}

read_key() {
  local key
  IFS= read -rsn1 key || return 1
  local action="other"
  local seq=""

  if [[ "$key" == $'\x1b' ]]; then
    IFS= read -rsn2 -t 1 seq || true
    case "$seq" in
      "[A"|"OA") action="up" ;;
      "[B"|"OB") action="down" ;;
      *) action="other" ;;
    esac
    echo "$action"
    return 0
  fi

  local key_hex
  key_hex="$(printf '%s' "$key" | od -An -tx1 | tr -d '[:space:]')"
  if [[ "$key_hex" == "e3" ]]; then
    IFS= read -rsn2 -t 1 seq || true
    key+="$seq"
    key_hex="$(printf '%s' "$key" | od -An -tx1 | tr -d '[:space:]')"
  fi
  if [[ "$key_hex" == "e38593" ]]; then
    action="down"
  elif [[ "$key_hex" == "e3858f" ]]; then
    action="up"
  fi

  if [[ "$action" == "other" ]]; then
    case "$key" in
      " ") action="space" ;;
      $'\n'|"") action="enter" ;;
      j|J) action="down" ;;
      k|K) action="up" ;;
      q|Q) action="quit" ;;
      *) action="other" ;;
    esac
  fi
  echo "$action"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
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
}

disable_input_echo() {
  stty -echo >/dev/null 2>&1 || true
}

prepare_terminal() {
  ORIG_STTY_SETTINGS="$(stty -g)"
  stty -echo -icanon min 1 time 0 >/dev/null 2>&1 || true
}

draw_mode_menu() {
  local cursor="$1"
  refresh_ui
  echo "백업이 존재합니다. 진행 모드를 선택하세요."
  echo
  echo "조작: ↑/↓ 또는 j/k 이동, Enter 선택, q 취소"
  echo

  local options=(
    "초기화 후 적용"
    "바로 새 적용"
  )

  local i marker
  for i in 0 1; do
    marker=" "
    [[ "$i" -eq "$cursor" ]] && marker=">"
    printf "%s %s\n" "$marker" "${options[$i]}"
  done
}

select_mode_if_backup_exists() {
  local cursor=0
  while true; do
    draw_mode_menu "$cursor"
    case "$(read_key)" in
      up)
        [[ "$cursor" -eq 0 ]] && cursor=1 || cursor=0
        ;;
      down)
        [[ "$cursor" -eq 1 ]] && cursor=0 || cursor=1
        ;;
      enter)
        if [[ "$cursor" -eq 0 ]]; then
          MODE="reset_apply"
        else
          MODE="apply_only"
        fi
        break
        ;;
      quit)
        echo
        echo "취소되었습니다."
        exit 0
        ;;
    esac
  done
}

draw_checkbox_menu() {
  local cursor="$1"
  local message="${2:-}"
  local i marker check

  refresh_ui
  echo "적용할 항목을 선택하세요."
  echo
  echo "조작: ↑/↓ 또는 j/k 이동, Space 체크, Enter 실행, q 취소"
  if [[ "$MODE" == "reset_apply" ]]; then
    echo "모드: 초기화 후 적용 (선택 항목 관련 복원 후 적용)"
  else
    echo "모드: 바로 새 적용"
  fi
  echo

  for i in "${!FEATURE_LABELS[@]}"; do
    marker=" "
    check=" "
    [[ "$i" -eq "$cursor" ]] && marker=">"
    [[ "${SELECTED[$i]}" -eq 1 ]] && check="x"
    printf "%s [%s] %s\n" "$marker" "$check" "${FEATURE_LABELS[$i]}"
  done

  if [[ -n "$message" ]]; then
    echo
    echo "⚠️  $message"
  fi
}

has_any_selection() {
  local i
  for i in "${!SELECTED[@]}"; do
    if [[ "${SELECTED[$i]}" -eq 1 ]]; then
      return 0
    fi
  done
  return 1
}

checkbox_select_actions() {
  local cursor=0
  local message=""
  local max_index=$(( ${#FEATURE_LABELS[@]} - 1 ))

  while true; do
    draw_checkbox_menu "$cursor" "$message"
    message=""

    case "$(read_key)" in
      up)
        if (( cursor == 0 )); then
          cursor="$max_index"
        else
          cursor=$((cursor - 1))
        fi
        ;;
      down)
        if (( cursor == max_index )); then
          cursor=0
        else
          cursor=$((cursor + 1))
        fi
        ;;
      space)
        if [[ "${SELECTED[$cursor]}" -eq 1 ]]; then
          SELECTED[$cursor]=0
        else
          SELECTED[$cursor]=1
        fi
        ;;
      enter)
        if has_any_selection; then
          break
        fi
        message="최소 1개 항목을 선택해주세요."
        ;;
      quit)
        echo
        echo "취소되었습니다."
        exit 0
        ;;
    esac
  done
}

add_step() {
  STEP_LABELS+=("$1")
  STEP_CMDS+=("$2")
}

has_step_command() {
  local target="$1"
  local i
  for i in "${!STEP_CMDS[@]}"; do
    if [[ "${STEP_CMDS[$i]}" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

build_execution_steps() {
  STEP_LABELS=()
  STEP_CMDS=()

  if [[ "$MODE" == "reset_apply" ]]; then
    for i in "${!SELECTED[@]}"; do
      if [[ "${SELECTED[$i]}" -eq 1 ]]; then
        if ! has_step_command "${FEATURE_RESET_CMDS[$i]}"; then
          add_step "${FEATURE_LABELS[$i]} 초기화 복원" "${FEATURE_RESET_CMDS[$i]}"
        fi
      fi
    done
  fi

  for i in "${!SELECTED[@]}"; do
    if [[ "${SELECTED[$i]}" -eq 1 ]]; then
      add_step "${FEATURE_LABELS[$i]}" "${FEATURE_APPLY_CMDS[$i]}"
    fi
  done
}

print_summary() {
  refresh_ui
  echo "실행 계획"
  echo
  if [[ "$MODE" == "reset_apply" ]]; then
    echo "- 모드: 초기화 후 적용"
  else
    echo "- 모드: 바로 새 적용"
  fi

  echo "- 선택 항목:"
  local i
  for i in "${!SELECTED[@]}"; do
    if [[ "${SELECTED[$i]}" -eq 1 ]]; then
      echo "  * ${FEATURE_LABELS[$i]}"
    fi
  done

  echo
  echo "- 실행 순서:"
  local idx
  for idx in "${!STEP_LABELS[@]}"; do
    printf "  %d. %s\n" "$((idx + 1))" "${STEP_LABELS[$idx]}"
  done

  echo
  echo "Enter를 누르면 실행합니다. (q 취소)"
  while true; do
    case "$(read_key)" in
      enter)
        break
        ;;
      quit)
        echo
        echo "취소되었습니다."
        exit 0
        ;;
    esac
  done
}

run_steps() {
  local total="${#STEP_CMDS[@]}"
  local idx

  refresh_ui
  echo "실행을 시작합니다."
  echo

  for idx in "${!STEP_CMDS[@]}"; do
    echo "[$((idx + 1))/$total] ${STEP_LABELS[$idx]}"
    if ! "${STEP_CMDS[$idx]}"; then
      echo
      echo "❌ 실패: ${STEP_LABELS[$idx]}" >&2
      exit 1
    fi
    echo "✅ 완료"
    echo
  done

  echo "모든 작업이 완료되었습니다."
}

has_any_backup() {
  [[ -d "$BACKUP_ROOT" ]] || return 1

  local item
  for item in "$BACKUP_ROOT"/*; do
    [[ -d "$item" ]] || continue
    return 0
  done

  return 1
}

main() {
  parse_args "$@"
  require_tty
  load_features

  tput civis >/dev/null 2>&1 || true
  prepare_terminal
  disable_input_echo

  if has_any_backup; then
    select_mode_if_backup_exists
  else
    MODE="apply_only"
  fi

  checkbox_select_actions
  build_execution_steps
  print_summary
  run_steps
}

main "$@"
