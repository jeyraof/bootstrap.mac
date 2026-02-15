# bootstrap.mac

맥 최초 셋업 시 자주 필요한 키보드 단축키/키 매핑 설정을 자동화하는 스크립트 모음입니다.

## 포함된 항목

- `set_input_source_shift_space.sh`
  - `com.apple.symbolichotkeys` 설정을 수정해 입력 소스 전환 단축키를 조정합니다.
  - 기존 설정 파일(`~/Library/Preferences/com.apple.symbolichotkeys.plist`)을 타임스탬프가 포함된 백업 파일로 먼저 저장합니다.
  - `60번`(이전 입력 소스) 단축키를 비활성화합니다.
  - `61번`(다음 입력 소스) 단축키를 `Shift + Space`로 설정합니다.
  - 적용을 위해 `cfprefsd`, `SystemUIServer`를 재시작합니다.

- `restore_symbolichotkeys.sh`
  - 백업해둔 plist 파일을 원래 설정 파일로 복원합니다.
  - 복원 후 `cfprefsd`, `SystemUIServer`를 재시작합니다.

- `set_spotlight_ctrl_space.sh`
  - Spotlight 단축키(64번)를 `Ctrl + Space`로 설정합니다.
  - 기존 설정 파일(`~/Library/Preferences/com.apple.symbolichotkeys.plist`)을 타임스탬프가 포함된 백업 파일로 먼저 저장합니다.
  - 적용을 위해 `cfprefsd`, `SystemUIServer`를 재시작합니다.

- `set_capslock_to_control.sh`
  - `ByHost .GlobalPreferences`의 키보드 modifier 매핑을 직접 수정해 `Caps Lock`을 `Left Control`로 매핑합니다.
  - 연결된 키보드 ID를 자동 탐지해 각 장치에 적용합니다.
  - 반영이 늦으면 로그아웃/로그인이 필요할 수 있습니다.

- `set_key_repeat_fast.sh`
  - `InitialKeyRepeat=15`, `KeyRepeat=1`로 키 반복 속도를 설정합니다.
  - 적용 전 현재 전역 설정값을 `~/Library/Preferences/.GlobalPreferences.keyrepeat.backup-YYYYMMDD-HHMMSS` 형식으로 백업합니다.
  - 반영을 위해 `cfprefsd`를 재시작합니다.

- `restore_key_repeat.sh`
  - `set_key_repeat_fast.sh`가 생성한 백업 파일을 읽어 key repeat 설정을 복원합니다.
  - 백업값이 `UNSET`이면 해당 키를 삭제해 기본값(미설정)으로 되돌립니다.

## 사용 방법

### 1) 입력 소스 단축키를 Shift + Space로 설정

```bash
./set_input_source_shift_space.sh
```

실행 후 출력되는 `백업 파일 경로`를 기록해두세요.

### 2) 기존 설정으로 복원

```bash
./restore_symbolichotkeys.sh ~/Library/Preferences/com.apple.symbolichotkeys.plist.backup-YYYYMMDD-HHMMSS
```

### 3) Spotlight를 Ctrl + Space로 설정

```bash
./set_spotlight_ctrl_space.sh
```

### 4) Caps Lock을 Control로 매핑

```bash
./set_capslock_to_control.sh
```

### 5) Key Repeat를 빠르게 설정 (Initial=15, Repeat=1)

```bash
./set_key_repeat_fast.sh
```

실행 후 출력되는 `백업 파일 경로`를 기록해두세요.

### 6) Key Repeat를 이전 값으로 복원

```bash
./restore_key_repeat.sh ~/Library/Preferences/.GlobalPreferences.keyrepeat.backup-YYYYMMDD-HHMMSS
```

## 주의사항

- 이 스크립트는 macOS 사용자 설정 파일(`~/Library/Preferences`)을 직접 수정합니다.
- 적용이 즉시 반영되지 않으면 로그아웃/로그인 또는 재부팅이 필요할 수 있습니다.
- macOS 버전에 따라 SymbolicHotKeys 내부 구조가 다를 수 있으니, 반드시 백업 파일을 확인한 뒤 적용하세요.
- 실행 권한이 없다면 `chmod +x ./*.sh`를 먼저 실행하세요.

## 권장 실행 순서 (신규 Mac)

1. macOS 초기 설정 완료
2. 터미널에서 저장소 클론
3. `set_input_source_shift_space.sh` 실행
4. `set_spotlight_ctrl_space.sh` 실행
5. `set_capslock_to_control.sh` 실행
6. 필요 시 `set_key_repeat_fast.sh` 실행
7. 동작 확인 후 필요 시 `restore_symbolichotkeys.sh`, `restore_key_repeat.sh`로 복원
