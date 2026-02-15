# bootstrap.mac

맥 최초 셋업 시 자주 필요한 키보드 단축키/키 매핑 설정을 자동화하는 스크립트 모음입니다.

## 백업 정책 (restore defaults 전용)

모든 백업은 `~/.bootstrap.mac/backups`에서 관리됩니다.

- `original`: 설정 변경 전 최초 상태(restore defaults 기준)

복원은 `original`만 사용해 수행합니다.

### 백업 디렉터리 구조

- `~/.bootstrap.mac/backups/symbolichotkeys/`
  - `original.plist`
  - `original.meta`
- `~/.bootstrap.mac/backups/keyrepeat/`
  - `original.env`
  - `original.meta`

## 포함된 항목

- `run.sh`
  - 체크박스 기반 인터랙티브 실행기입니다.
  - `space`로 항목을 체크하고 `enter`로 실행합니다.
  - 백업(`original`)이 없으면 바로 적용 항목을 선택합니다.
  - 백업이 있으면 `초기화 후 적용` 또는 `바로 새 적용` 모드를 먼저 선택합니다.
  - `초기화 후 적용`에서는 선택 항목과 관련된 복원만 선행한 뒤 설정을 적용합니다.

- `set_input_source_shift_space.sh`
  - 입력 소스 전환 단축키를 조정합니다.
  - `60번`(이전 입력 소스) 단축키를 비활성화합니다.
  - `61번`(다음 입력 소스) 단축키를 `Shift + Space`로 설정합니다.
  - 최초 실행이면 `original`을 생성합니다.
  - `--refresh-original` 옵션으로 `original`을 강제 갱신할 수 있습니다.

- `set_spotlight_ctrl_space.sh`
  - Spotlight 단축키(64번)를 `Ctrl + Space`로 설정합니다.
  - 최초 실행이면 `original`을 생성합니다.
  - `--refresh-original` 옵션으로 `original`을 강제 갱신할 수 있습니다.

- `set_key_repeat_fast.sh`
  - `InitialKeyRepeat=15`, `KeyRepeat=1`로 키 반복 속도를 설정합니다.
  - 최초 실행이면 `original`을 생성합니다.
  - `--refresh-original` 옵션으로 `original`을 강제 갱신할 수 있습니다.

- `restore_symbolichotkeys.sh`
  - `symbolichotkeys`의 `original.plist`로 restore defaults를 수행합니다.
  - 인자 없이 실행합니다.

- `restore_key_repeat.sh`
  - `keyrepeat`의 `original.env`로 restore defaults를 수행합니다.
  - 인자 없이 실행합니다.

## 사용 방법

### 1) 인터랙티브로 한 번에 선택 적용 (`run.sh`)

```bash
./run.sh
```

키 조작:

- `↑/↓` 또는 `j/k`: 이동
- `space`: 체크/해제
- `enter`: 실행
- `q`: 취소

### 2) 입력 소스 단축키를 Shift + Space로 설정

```bash
./set_input_source_shift_space.sh
```

`original`을 강제 갱신하려면:

```bash
./set_input_source_shift_space.sh --refresh-original
```

### 3) Spotlight를 Ctrl + Space로 설정

```bash
./set_spotlight_ctrl_space.sh
```

### 4) Key Repeat를 빠르게 설정 (Initial=15, Repeat=1)

```bash
./set_key_repeat_fast.sh
```

### 5) SymbolicHotKeys restore defaults

```bash
./restore_symbolichotkeys.sh
```

### 6) Key Repeat restore defaults

```bash
./restore_key_repeat.sh
```

## 주의사항

- 이 스크립트는 macOS 사용자 설정 파일(`~/Library/Preferences`)을 직접 수정합니다.
- 적용이 즉시 반영되지 않으면 로그아웃/로그인 또는 재부팅이 필요할 수 있습니다.
- macOS 버전에 따라 SymbolicHotKeys 내부 구조가 다를 수 있으니, 적용 전 백업 파일을 확인하세요.
- 실행 권한이 없다면 `chmod +x ./*.sh`를 먼저 실행하세요.
- restore defaults는 하드코딩 기본값이 아니라 저장된 `original` 기준입니다.

## 권장 실행 순서 (신규 Mac)

1. macOS 초기 설정 완료
2. 터미널에서 저장소 클론
3. `run.sh` 실행 후 필요한 항목 체크하여 적용
4. 필요 시 개별 스크립트(`set_*`, `restore_*`)로 추가 조정
