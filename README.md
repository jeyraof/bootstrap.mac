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

## 구조

> 작업 전 규칙: `AGENTS.md`를 먼저 확인하세요.  
> AI Agent 기반 자동화/수정 시 적용/검토/복원 규칙이 정의되어 있습니다.

- `run.sh`
  - 체크박스 기반 인터랙티브 실행기
  - 백업(`original`) 존재 시 모드를 선택 후 실행
- `features/`
  - 기능 단위 디렉토리
  - 각 기능은 `feature.sh`, `description`, `set.sh`, `reset.sh`를 가짐
  - `run.sh`는 `features`의 메타데이터만 읽어 동적으로 메뉴를 구성

현재 기능 목록:

- `001_input_source_shift_space`
  - `입력 소스 전환 Shift + Space 적용`
- `002_spotlight_ctrl_space`
  - `Spotlight Ctrl + Space 적용`
- `003_key_repeat_fast`
  - `Key Repeat 빠르게 적용`

개별 기능은 각 `features/<id>/set.sh`, `features/<id>/reset.sh` 경로로 직접 실행할 수 있으며,
`run.sh`에서 동적으로 메뉴를 구성합니다.

## 새 기능 추가

1. 기능 디렉토리 생성

```bash
mkdir features/004_my_new_feature
cp -R features/_template/* features/004_my_new_feature/
```

2. `/features/004_my_new_feature/set.sh`, `reset.sh`, `feature.sh`, `description` 수정

   - `feature.sh`의 `FEATURE_ID`를 번호 접두사 포함한 고유 ID로 변경
   - `FEATURE_ENABLED=1`이면 기본 노출, `0`이면 run.sh 메뉴에서 숨김

3. `set.sh`, `reset.sh`는 실행권한 필요

```bash
chmod +x features/004_my_new_feature/{set.sh,reset.sh}
```

4. `run.sh`를 다시 실행하면 새 기능이 자동으로 메뉴에 노출됩니다.

실행 순서는 `features/` 디렉토리 이름 오름차순(`001_...`, `002_...`)으로 결정되며,
`features/_template`은 자동으로 건너뜁니다.

### feature.sh 체크리스트

`feature.sh`에서 다음 항목은 필수이며, 빠지면 `run.sh` 실행 시 즉시 실패합니다.

- `FEATURE_ID`: 기능 고유 ID (권장: `004_key_repeat_slow`)
- `FEATURE_LABEL`: 메뉴 라벨
- `FEATURE_DESCRIPTION_PATH`: 설명 파일 경로
- `FEATURE_APPLY_SCRIPT`: 적용 스크립트 경로
- `FEATURE_RESET_SCRIPT`: 복원 스크립트 경로
- `FEATURE_ENABLED`: 기본 `1`(노출), `0`(숨김)
- `FEATURE_DESCRIPTION_PATH`는 실행 시 읽을 수 있는 텍스트 파일이어야 함

예시:

```bash
FEATURE_ID="004_example"
FEATURE_LABEL="예시 기능"
FEATURE_DESCRIPTION_PATH="$SCRIPT_DIR/description"
FEATURE_APPLY_SCRIPT="$SCRIPT_DIR/set.sh"
FEATURE_RESET_SCRIPT="$SCRIPT_DIR/reset.sh"
FEATURE_ENABLED=1
```

`set.sh`/`reset.sh`는 독립 실행 가능한 형태여야 합니다.

## 사용 방법

### 원격 실행 엔트리포인트

```bash
curl -fsSL https://leejaeyoung.org/bootstrap.mac.sh | bash
```

- 위 스크립트는 저장소를 내려받아 실행하고 `run.sh`를 바로 실행합니다.
- `run.sh`가 TTY 기반이라, 원격 실행 스크립트는 `/dev/tty`를 통해 상호작용을 이어받아 메뉴 선택이 가능합니다.
- 실행 후에는 임시로 받아온 파일을 정리하므로 설정 파일을 제외하면 사용자 홈에 잔재를 남기지 않습니다.

기본적으로 HTTPS + `raw.githubusercontent.com`로 302 리다이렉트를 따라갑니다.

### 1) 인터랙티브로 한 번에 선택 적용 (`run.sh`)

```bash
./run.sh
```

키 조작:

- `↑/↓` 또는 `j/k`: 이동
- `space`: 체크/해제
- `enter`: 실행
- `q`: 취소

### 2) 개별 기능 실행

```bash
./features/001_input_source_shift_space/set.sh
./features/002_spotlight_ctrl_space/set.sh
./features/003_key_repeat_fast/set.sh
./features/001_input_source_shift_space/reset.sh
./features/003_key_repeat_fast/reset.sh
```

`--refresh-original`은 각 `set.sh`에서 지원됩니다.

## 주의사항

- 이 스크립트는 macOS 사용자 설정 파일(`~/Library/Preferences`)을 직접 수정합니다.
- 적용이 즉시 반영되지 않으면 로그아웃/로그인 또는 재부팅이 필요할 수 있습니다.
- macOS 버전에 따라 SymbolicHotKeys 내부 구조가 다를 수 있으니, 적용 전 백업 파일을 확인하세요.
- 실행 권한이 없다면 `chmod +x ./*.sh`를 먼저 실행하세요.
- restore defaults는 하드코딩 기본값이 아니라 저장된 `original` 기준입니다.
