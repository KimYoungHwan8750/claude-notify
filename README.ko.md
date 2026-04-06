# claude-code-toast

[English](README.md) | 한국어

Claude Code를 위한 Windows 토스트 알림. 터미널을 계속 쳐다보지 않아도 작업 완료를 바로 알 수 있습니다.

![Windows 11](https://img.shields.io/badge/Windows%2011-0078D4?logo=windows11&logoColor=white)
![Claude Code](https://img.shields.io/badge/Claude%20Code-Hook-orange)

## 주요 기능

- Claude Code가 응답을 끝내거나 입력을 기다릴 때 Windows 토스트 알림 표시
- **프로젝트 이름**과 Claude 응답의 **요약 내용** 표시
- **스마트 클릭 동작**:
  - 에디터에서 해당 프로젝트가 이미 열려있으면 → 클릭 시 그 창으로 포커스
  - 열려있지 않으면 (터미널로만 작업 중) → 클릭해도 아무것도 안 열림 (원치 않는 새 창 방지)
- 사용자가 직접 닫을 때까지 알림이 **유지됨** (놓치는 알림 없음)
- **다국어 지원** — 영어 (기본값) / 한국어 내장

## 지원 에디터

| 에디터 | 프로토콜 | 사용법 |
|--------|----------|--------|
| VS Code | `vscode://` | 기본값 |
| Cursor | `cursor://` | `--editor cursor` |
| Windsurf | `windsurf://` | `--editor windsurf` |

`<name>://file/<path>` 형식의 프로토콜을 지원하는 에디터라면 이름만 넘기면 동작합니다.

## 설치

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-toast.git
cd claude-code-toast
bash install.sh
```

Cursor를 기본 에디터로 설치:
```bash
bash install.sh --editor cursor
```

한국어로 설치:
```bash
bash install.sh --editor cursor --lang ko
```

## 수동 설치

1. `notify-hook.sh`, `notify-hook.ps1` 파일을 `~/.claude/claude-code-toast/`에 복사
2. `config.json` 생성:
   ```json
   {
     "editor": "vscode",
     "lang": "ko"
   }
   ```
3. `~/.claude/settings.json`에 hook 추가:
   ```json
   {
     "hooks": {
       "Stop": [{"matcher": "", "hooks": [{"type": "command", "command": "bash ~/.claude/claude-code-toast/notify-hook.sh", "timeout": 8}]}],
       "Notification": [{"matcher": "", "hooks": [{"type": "command", "command": "bash ~/.claude/claude-code-toast/notify-hook.sh", "timeout": 8}]}]
     }
   }
   ```

## 동작 원리

```
Claude Code (Stop / Notification 이벤트)
  → stdin JSON을 notify-hook.sh로 전달
  → 임시 파일로 저장 (start 명령은 stdin을 전달 못 함)
  → start로 데스크톱 세션에서 PowerShell 실행
  → notify-hook.ps1이 JSON을 읽음
  → 에디터 프로세스의 창 타이틀을 확인해 프로젝트 열림 여부 판단
  → 열림 상태에 따라 launch URI가 있거나 없는 toast XML 생성
  → Windows Toast API로 지속 알림 표시
  → 클릭 시 protocol URI로 에디터 포커스
```

### 스마트 클릭 동작

알림을 클릭하면 스크립트가 대상 에디터가 해당 프로젝트와 함께 실행 중인지
확인합니다. 에디터 프로세스(`Code.exe`, `Cursor.exe` 등)를 열거하고, 각 창의
타이틀을 ` - `로 분리한 세그먼트 중에 프로젝트 폴더 이름이 있는지 비교합니다.

- **프로젝트가 열려있음** → `<editor>://file/<path>` 프로토콜로 기존 창에 포커스
- **프로젝트가 열려있지 않음** → 핸들러가 없는 background activation으로 처리되어
  새 에디터 창이 열리지 않고 알림만 닫힘 (터미널 작업 중일 때 유용)

## 문제 해결

### 알림이 뜨지 않아요
- **방해 금지 모드 / 집중 지원**이 꺼져 있어야 합니다 (가장 흔한 원인)
- Windows 설정 > 시스템 > 알림에서 알림이 켜져있는지 확인

### 알림이 떴다가 바로 사라져요
- Windows 알림 설정에서 제어됩니다
- 설정 > 시스템 > 알림 > 표시 시간 조정

### 클릭해도 에디터 포커스가 안 돼요
- 에디터가 프로토콜 핸들러로 등록되어 있어야 합니다 (포터블 버전이 아닌 정상 설치 버전)

## 설정

`~/.claude/claude-code-toast/config.json` 파일 수정:

```json
{
  "editor": "cursor",
  "lang": "ko"
}
```

| 키 | 설명 | 기본값 |
|-----|------|--------|
| `editor` | 알림 클릭 시 포커스할 에디터 프로토콜 이름 | `vscode` |
| `lang` | 알림 언어 (`en`, `ko`) | `en` |

### 지원 언어

| 코드 | 언어 | `Notification` 이벤트 본문 |
|------|------|--------------------------|
| `en` | 영어 | `Waiting for input` |
| `ko` | 한국어 | `입력 대기 중` |

재시작 불필요 — 다음 알림부터 바로 반영됩니다.

## 요구사항

- Windows 10/11
- Hook을 지원하는 Claude Code
- Git Bash (Git for Windows에 포함됨)

## 삽질 노트

이 프로젝트를 만들면서 겪은 주요 삽질들:

1. **CLI 환경에서 직접 PowerShell Toast API 호출 불가** — `start ""`로 데스크톱 세션에서 실행해야 함
2. **Hook의 stdin이 `start`로 전달 안 됨** — 파일로 중계 필요
3. **PowerShell 한글 깨짐** — `-Encoding UTF8` 명시 필수
4. **`-ActivatedAction` 콜백이 동작 안 함** — 프로세스 종료 후에는 호출 불가, Toast XML의 `launch` 속성과 `activationType="protocol"` 사용으로 해결
5. **방해 금지 모드** — 알림이 안 뜨는 가장 흔한 원인

## 라이선스

MIT
