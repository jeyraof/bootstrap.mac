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

| 구성 | 설명 |
|---|---|
| `run.sh` | 인터랙티브 실행기. 백업 존재 시 모드 선택 후 적용/복원 |
| `features/` | 기능 단위 디렉토리 (`feature.sh`, `set.sh`, `reset.sh`, `description`) |
| `run.sh` 동작 | `features/*/feature.sh` 메타를 읽어 메뉴 동적 구성 |

현재 기능 목록:

| ordinal | 설명 |
|---|---|
| `001` | 입력 소스 전환 Shift + Space 적용 |
| `002` | Spotlight Ctrl + Space 적용 |
| `003` | Key Repeat 빠르게 적용 |

`run.sh`에서 동적으로 메뉴를 구성하며, 인터랙티브로만 실행할 수 있습니다.

## 새 기능 추가

1. `features/_template`을 새 디렉토리로 복사하고 (`features/00X_...`)
2. `feature.sh`에서 `FEATURE_ID`/`FEATURE_LABEL`/`FEATURE_ENABLED`와 스크립트 경로를 설정
3. `set.sh`, `reset.sh`에 `chmod +x` 권한 부여
4. `run.sh` 실행 시 새 행이 자동 노출됨

정렬은 `features` 폴더 이름 오름차순(`001_...`, `002_...`) 기준, `_template`은 제외됨.

### feature.sh 최소 필드

- `FEATURE_ID`, `FEATURE_LABEL`, `FEATURE_DESCRIPTION_PATH`, `FEATURE_APPLY_SCRIPT`, `FEATURE_RESET_SCRIPT`, `FEATURE_ENABLED`

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

개별 `set.sh`/`reset.sh`는 기능 단위 내부 실행 진입점이므로 일반 사용자 안내 대상에서 제외합니다.

## 주의사항

- 이 스크립트는 macOS 사용자 설정 파일(`~/Library/Preferences`)을 직접 수정합니다.
- 적용이 즉시 반영되지 않으면 로그아웃/로그인 또는 재부팅이 필요할 수 있습니다.
- macOS 버전에 따라 SymbolicHotKeys 내부 구조가 다를 수 있으니, 적용 전 백업 파일을 확인하세요.
- 실행 권한이 없다면 `chmod +x ./*.sh`를 먼저 실행하세요.
- restore defaults는 하드코딩 기본값이 아니라 저장된 `original` 기준입니다.
