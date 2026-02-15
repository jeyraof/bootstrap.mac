# bootstrap.mac

맥 최초 셋업 시 자주 필요한 입력 소스 단축키 설정을 자동화하는 스크립트 모음입니다.

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

## 사용 방법

### 1) 입력 소스 단축키를 Shift + Space로 설정

```bash
bash ./set_input_source_shift_space.sh
```

실행 후 출력되는 `백업 파일 경로`를 기록해두세요.

### 2) 기존 설정으로 복원

```bash
bash ./restore_symbolichotkeys.sh ~/Library/Preferences/com.apple.symbolichotkeys.plist.backup-YYYYMMDD-HHMMSS
```

## 주의사항

- 이 스크립트는 macOS 사용자 설정 파일(`~/Library/Preferences`)을 직접 수정합니다.
- 적용이 즉시 반영되지 않으면 로그아웃/로그인 또는 재부팅이 필요할 수 있습니다.
- macOS 버전에 따라 SymbolicHotKeys 내부 구조가 다를 수 있으니, 반드시 백업 파일을 확인한 뒤 적용하세요.

## 권장 실행 순서 (신규 Mac)

1. macOS 초기 설정 완료
2. 터미널에서 저장소 클론
3. `set_input_source_shift_space.sh` 실행
4. 동작 확인 후 필요 시 `restore_symbolichotkeys.sh`로 복원
