#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BACKUP_SYMBOLICHOTKEYS="$HOME/.bootstrap.mac/backups/symbolichotkeys/original.plist"
BACKUP_KEYREPEAT="$HOME/.bootstrap.mac/backups/keyrepeat/original.env"

MODE="apply_only"
SELECTED=(0 0 0)

ACTION_LABELS=(
  "입력 소스 전환 Shift + Space 적용"
  "Spotlight Ctrl + Space 적용"
  "Key Repeat 빠르게 적용"
)

ACTION_SCRIPTS=(
  "$SCRIPT_DIR/set_input_source_shift_space.sh"
  "$SCRIPT_DIR/set_spotlight_ctrl_space.sh"
  "$SCRIPT_DIR/set_key_repeat_fast.sh"
)

RESTORE_SYMBOLICHOTKEYS_SCRIPT="$SCRIPT_DIR/restore_symbolichotkeys.sh"
RESTORE_KEYREPEAT_SCRIPT="$SCRIPT_DIR/restore_key_repeat.sh"

STEP_LABELS=()
STEP_CMDS=()

cleanup() {
  tput cnorm >/dev/null 2>&1 || true
  stty echo >/dev/null 2>&1 || true
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

require_dependencies() {
  local path
  for path in "${ACTION_SCRIPTS[@]}" "$RESTORE_SYMBOLICHOTKEYS_SCRIPT" "$RESTORE_KEYREPEAT_SCRIPT"; do
    if [[ ! -f "$path" ]]; then
      echo "❌ 필수 스크립트를 찾을 수 없습니다: $path" >&2
      exit 1
    fi
    if [[ ! -x "$path" ]]; then
      echo "❌ 실행 권한이 없습니다: $path" >&2
      echo "   chmod +x \"$path\"" >&2
      exit 1
    fi
  done
}

has_any_backup() {
  [[ -f "$BACKUP_SYMBOLICHOTKEYS" || -f "$BACKUP_KEYREPEAT" ]]
}

read_key() {
  local key
  IFS= read -rsn1 key || return 1

  if [[ "$key" == $'\x1b' ]]; then
    IFS= read -rsn1 -t 0.01 key || true
    if [[ "$key" == "[" ]]; then
      IFS= read -rsn1 -t 0.01 key || true
      case "$key" in
        A) echo "up" ;;
        B) echo "down" ;;
        *) echo "other" ;;
      esac
      return 0
    fi
    echo "other"
    return 0
  fi

  case "$key" in
    " ") echo "space" ;;
    "") echo "enter" ;;
    j|J) echo "down" ;;
    k|K) echo "up" ;;
    q|Q) echo "quit" ;;
    *) echo "other" ;;
  esac
}

draw_mode_menu() {
  local cursor="$1"
  clear
  printf "백업이 존재합니다. 진행 모드를 선택하세요.\n\n"
  printf "조작: ↑/↓ 또는 j/k 이동, Enter 선택, q 취소\n\n"

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
        cursor=$(( (cursor + 1) % 2 ))
        ;;
      down)
        cursor=$(( (cursor + 1) % 2 ))
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

  clear
  printf "적용할 항목을 선택하세요.\n\n"
  printf "조작: ↑/↓ 또는 j/k 이동, Space 체크, Enter 실행, q 취소\n"
  if [[ "$MODE" == "reset_apply" ]]; then
    printf "모드: 초기화 후 적용 (선택 항목 관련 복원 후 적용)\n"
  else
    printf "모드: 바로 새 적용\n"
  fi
  printf "\n"

  local i pointer check
  for i in 0 1 2; do
    pointer=" "
    check=" "
    [[ "$i" -eq "$cursor" ]] && pointer=">"
    [[ "${SELECTED[$i]}" -eq 1 ]] && check="x"
    printf "%s [%s] %s\n" "$pointer" "$check" "${ACTION_LABELS[$i]}"
  done

  if [[ -n "$message" ]]; then
    printf "\n⚠️  %s\n" "$message"
  fi
}

has_any_selection() {
  local i
  for i in 0 1 2; do
    if [[ "${SELECTED[$i]}" -eq 1 ]]; then
      return 0
    fi
  done
  return 1
}

checkbox_select_actions() {
  local cursor=0
  local message=""

  while true; do
    draw_checkbox_menu "$cursor" "$message"
    message=""

    case "$(read_key)" in
      up)
        cursor=$(( (cursor + 2) % 3 ))
        ;;
      down)
        cursor=$(( (cursor + 1) % 3 ))
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

build_execution_steps() {
  STEP_LABELS=()
  STEP_CMDS=()

  if [[ "$MODE" == "reset_apply" ]]; then
    if [[ "${SELECTED[0]}" -eq 1 || "${SELECTED[1]}" -eq 1 ]]; then
      add_step "SymbolicHotKeys 초기화 복원" "$RESTORE_SYMBOLICHOTKEYS_SCRIPT"
    fi
    if [[ "${SELECTED[2]}" -eq 1 ]]; then
      add_step "Key Repeat 초기화 복원" "$RESTORE_KEYREPEAT_SCRIPT"
    fi
  fi

  local i
  for i in 0 1 2; do
    if [[ "${SELECTED[$i]}" -eq 1 ]]; then
      add_step "${ACTION_LABELS[$i]}" "${ACTION_SCRIPTS[$i]}"
    fi
  done
}

print_summary() {
  clear
  printf "실행 계획\n\n"
  if [[ "$MODE" == "reset_apply" ]]; then
    printf "- 모드: 초기화 후 적용\n"
  else
    printf "- 모드: 바로 새 적용\n"
  fi

  printf "- 선택 항목:\n"
  local i
  for i in 0 1 2; do
    if [[ "${SELECTED[$i]}" -eq 1 ]]; then
      printf "  * %s\n" "${ACTION_LABELS[$i]}"
    fi
  done

  printf "\n- 실행 순서:\n"
  local idx
  for idx in "${!STEP_LABELS[@]}"; do
    printf "  %d. %s\n" "$((idx + 1))" "${STEP_LABELS[$idx]}"
  done

  printf "\nEnter를 누르면 실행합니다. (q 취소)\n"
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

  clear
  printf "실행을 시작합니다.\n\n"

  for idx in "${!STEP_CMDS[@]}"; do
    printf "[%d/%d] %s\n" "$((idx + 1))" "$total" "${STEP_LABELS[$idx]}"
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

main() {
  require_tty
  require_dependencies

  tput civis >/dev/null 2>&1 || true

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
