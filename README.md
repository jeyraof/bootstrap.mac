# bootstrap.mac

맥 최초 셋업 시 자주 필요한 키보드 단축키/키 매핑 설정을 자동화하는 스크립트 모음입니다.

## 백업 정책 (통합)

모든 백업은 `~/.bootstrap.mac/backups`에서 관리됩니다.

- `original`: 맥 설정을 시작할 때의 최초 상태(기본적으로 불변)
- `snapshot`: 각 설정 적용 직전 상태(누적 보관)

복원 시에는 `original` 또는 원하는 시점의 `snapshot` 중 하나를 선택할 수 있습니다.

### 백업 디렉터리 구조

- `~/.bootstrap.mac/backups/symbolichotkeys/`
  - `original.plist`
  - `original.meta`
  - `snapshots/<YYYYMMDD-HHMMSS>.plist`
  - `snapshots/<YYYYMMDD-HHMMSS>.meta`
- `~/.bootstrap.mac/backups/keyrepeat/`
  - `original.env`
  - `original.meta`
  - `snapshots/<YYYYMMDD-HHMMSS>.env`
  - `snapshots/<YYYYMMDD-HHMMSS>.meta`

## 포함된 항목

- `set_input_source_shift_space.sh`
  - 입력 소스 전환 단축키를 조정합니다.
  - `60번`(이전 입력 소스) 단축키를 비활성화합니다.
  - `61번`(다음 입력 소스) 단축키를 `Shift + Space`로 설정합니다.
  - 실행 시 `symbolichotkeys`의 `snapshot`을 저장하고, 최초 실행이면 `original`도 생성합니다.
  - `--refresh-original` 옵션으로 `original`을 강제 갱신할 수 있습니다.

- `set_spotlight_ctrl_space.sh`
  - Spotlight 단축키(64번)를 `Ctrl + Space`로 설정합니다.
  - 실행 시 `symbolichotkeys`의 `snapshot`을 저장하고, 최초 실행이면 `original`도 생성합니다.
  - `--refresh-original` 옵션으로 `original`을 강제 갱신할 수 있습니다.

- `set_key_repeat_fast.sh`
  - `InitialKeyRepeat=15`, `KeyRepeat=1`로 키 반복 속도를 설정합니다.
  - 실행 시 `keyrepeat`의 `snapshot`을 저장하고, 최초 실행이면 `original`도 생성합니다.
  - `--refresh-original` 옵션으로 `original`을 강제 갱신할 수 있습니다.

- `restore_symbolichotkeys.sh`
  - `symbolichotkeys` 백업 목록에서 복원할 시점을 선택해 복원합니다.
  - `--list`, `--select <index>`를 지원합니다.
  - 기존처럼 백업 파일 경로를 직접 인자로 넘기는 방식도 지원합니다(하위호환).

- `restore_key_repeat.sh`
  - `keyrepeat` 백업 목록에서 복원할 시점을 선택해 복원합니다.
  - `--list`, `--select <index>`를 지원합니다.
  - 기존처럼 백업 파일 경로를 직접 인자로 넘기는 방식도 지원합니다(하위호환).

- `set_capslock_to_control.sh`
  - `ByHost .GlobalPreferences`의 키보드 modifier 매핑을 직접 수정해 `Caps Lock`을 `Left Control`로 매핑합니다.
  - 연결된 키보드 ID를 자동 탐지해 각 장치에 적용합니다.
  - 이 스크립트는 현재 통합 백업 체계(`original/snapshot`) 범위에서 제외되어 있습니다.

## 사용 방법

### 1) 입력 소스 단축키를 Shift + Space로 설정

```bash
./set_input_source_shift_space.sh
```

`original`을 강제 갱신하려면:

```bash
./set_input_source_shift_space.sh --refresh-original
```

### 2) Spotlight를 Ctrl + Space로 설정

```bash
./set_spotlight_ctrl_space.sh
```

### 3) Key Repeat를 빠르게 설정 (Initial=15, Repeat=1)

```bash
./set_key_repeat_fast.sh
```

### 4) SymbolicHotKeys 복원

대화형 선택:

```bash
./restore_symbolichotkeys.sh
```

목록 확인:

```bash
./restore_symbolichotkeys.sh --list
```

인덱스로 복원:

```bash
./restore_symbolichotkeys.sh --select 2
```

기존 방식(경로 직접 지정, 하위호환):

```bash
./restore_symbolichotkeys.sh ~/Library/Preferences/com.apple.symbolichotkeys.plist.backup-YYYYMMDD-HHMMSS
```

### 5) Key Repeat 복원

대화형 선택:

```bash
./restore_key_repeat.sh
```

목록 확인:

```bash
./restore_key_repeat.sh --list
```

인덱스로 복원:

```bash
./restore_key_repeat.sh --select 2
```

기존 방식(경로 직접 지정, 하위호환):

```bash
./restore_key_repeat.sh ~/Library/Preferences/.GlobalPreferences.keyrepeat.backup-YYYYMMDD-HHMMSS
```

## 주의사항

- 이 스크립트는 macOS 사용자 설정 파일(`~/Library/Preferences`)을 직접 수정합니다.
- 적용이 즉시 반영되지 않으면 로그아웃/로그인 또는 재부팅이 필요할 수 있습니다.
- macOS 버전에 따라 SymbolicHotKeys 내부 구조가 다를 수 있으니, 백업 목록을 확인한 뒤 적용하세요.
- 실행 권한이 없다면 `chmod +x ./*.sh`를 먼저 실행하세요.

## 권장 실행 순서 (신규 Mac)

1. macOS 초기 설정 완료
2. 터미널에서 저장소 클론
3. `set_input_source_shift_space.sh` 실행
4. `set_spotlight_ctrl_space.sh` 실행
5. `set_capslock_to_control.sh` 실행
6. 필요 시 `set_key_repeat_fast.sh` 실행
7. 동작 확인 후 필요 시 `restore_symbolichotkeys.sh`, `restore_key_repeat.sh`로 복원
