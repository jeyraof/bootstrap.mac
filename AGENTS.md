# AGENTS 가이드

## 프로젝트 개요
- 이 저장소는 macOS 초기 설정 자동화 스크립트 모음입니다.
- Bash 기반 `run.sh` 런처와, `features/` 하위의 개별 기능 스크립트를 통해 시스템 설정을 적용/복원합니다.
- 백업은 `~/.bootstrap.mac/backups` 아래 `original` 형태로 저장되며, 복원은 `original` 기준입니다.

## 필수 실행 규칙
- 기본 실행 인터페이스는 `./run.sh` 입니다.
- `run.sh`는 TTY 환경에서만 동작합니다 (`stdin/stdout` 터미널 필요).
- 기능 스크립트는 `set -euo pipefail` 사용이 기본입니다.
- 설정 적용 전/복구를 안전하게 하려면 `backup_common.sh` 제공 함수를 사용해야 합니다.
- 시스템 설정을 실제로 바꾸는 스크립트는 가능하면 공통 백업 경로(`~/.bootstrap.mac/backups/...`)를 함께 관리해야 합니다.

## 핵심 디렉터리/파일 규칙
- `run.sh`
  - `features/`를 스캔해 메뉴를 구성하고 실행합니다.
  - `*/_template` 디렉터리는 무시합니다.
- `features/<id>/`
  - `feature.sh`: 필수 메타데이터/인터페이스
  - `description`: 사용자에게 보여줄 기능 설명(텍스트)
  - `set.sh`: 적용 스크립트
  - `reset.sh`: 복원 스크립트
- `backup_common.sh`
  - `save_original_once`, `original_path`, `backup_root` 등 백업 유틸

## feature 모듈 인터페이스(필수)
`feature.sh`는 아래 항목이 모두 정의되어야 하며, 누락 시 `run.sh`가 즉시 실패합니다.
- `FEATURE_ID` (예: `004_new_feature`)
- `FEATURE_LABEL` (메뉴 라벨)
- `FEATURE_DESCRIPTION_PATH` (설명 파일 경로)
- `FEATURE_APPLY_SCRIPT` (보통 `set.sh`)
- `FEATURE_RESET_SCRIPT` (보통 `reset.sh`)
- `FEATURE_ENABLED` (`1`: 노출, `0`: 숨김)

`set.sh`/`reset.sh`는 직접 실행 가능한 형태여야 하며, `run.sh` 없이도 개별 실행이 가능해야 합니다.

## 신규 기능 추가 규칙
1. `features/NNN_이름` 디렉터리 생성
2. `features/_template/*` 복제 후 `feature.sh`의 `FEATURE_ID`/`FEATURE_LABEL`/`*_SCRIPT`/`FEATURE_ENABLED` 설정
3. `set.sh`, `reset.sh`에 실행 권한 부여 (`chmod +x`)
4. 기능 설명 업데이트 (`description`)
5. `./run.sh`로 UI 목록에 노출되는지 확인

## 코딩 스타일 가이드
- 셸 문법은 단순하고 명시적으로 작성
- 새 파일/수정은 macOS 경로(`$HOME`, `~` 해석)와 기존 백업 패턴을 존중
- `run.sh`에서 로드 가능한 구조를 깨뜨리는 방식(필수 변수 미정의, 권한 누락, 경로 잘못 설정)으로 수정하지 않기
- `original` 백업을 덮어쓸 때는 `--refresh-original` 동작을 고려

## 보안/안전 주의사항
- macOS `~/Library/Preferences`에 직접 쓰기 때문에, 테스트 전 대상 범위와 백업 존재 여부를 확인해야 합니다.
- 새 기능은 적용 후 바로 복구 가능한 `reset.sh`를 반드시 함께 제공해야 합니다.
- 사용자 동의 없이 기존 백업(`original`)을 임의로 삭제하지 않습니다.
