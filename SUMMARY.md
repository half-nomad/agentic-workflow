# Agentic Workflow Improvement Project

Oh My OpenCode(OMO) 프로젝트 패턴을 분석하여 Claude Code에 적용한 에이전틱 워크플로우 시스템.

---

## 요약 (Summary)


7개 커스텀 에이전트, 3개 슬래시 커맨드, 3개 자동화 훅으로 구성된 워크플로우 시스템 구축 완료.

### 생성된 구성요소

| 카테고리 | 항목 | 모델 | 용도 |
|----------|------|------|------|
| **에이전트** | oracle | opus | 전략 자문, 실패 분석 |
| | frontend-engineer | opus | UI/UX 코드 작성 |
| | backend-engineer | opus | 서버/API/DB 로직 |
| | test-engineer | sonnet | 테스트 코드 작성 |
| | librarian | sonnet | 문서/라이브러리 조사 |
| | explorer | sonnet | 코드베이스 탐색 |
| | document-writer | sonnet | 기술 문서 작성 |
| **커맨드** | /ralph | - | 자율 반복 실행 모드 |
| | /ultrawork | - | 병렬 에이전트 모드 |
| | /oracle | - | 전략 자문 호출 |
| **훅** | Keyword Detector | UserPromptSubmit | 키워드 감지 |
| | Todo Enforcer | Notification | TODO 완료 확인 |
| | Comment Checker | PostToolUse | 주석 검증 |

---

## 목적 (Purpose)

1. **작업 효율성**: 반복 워크플로우 자동화
2. **전문성 분리**: 역할별 에이전트로 최적 결과물 생성
3. **비용 최적화**: 작업 복잡도에 따른 모델 선택
4. **품질 보증**: 훅을 통한 자동 검증

---

## 취지 (Intent)

Claude Code 기본 에이전트로는 복잡한 개발 워크플로우 처리가 비효율적.
OMO에서 검증된 패턴 적용:

- **Ralph Loop**: 실패해도 포기하지 않는 끈질긴 실행
- **Oracle**: 막힌 상황에서 대안적 접근법 제시
- **Parallel Execution**: 독립 작업의 동시 처리
- **Keyword Activation**: 자연어로 모드 전환

---

## 동기 (Motivation)

### OMO 분석 결과
- 16개 전문 에이전트 (sisyphus, oracle, librarian 등)
- 22개 자동화 훅
- LSP/AST 기반 코드 분석
- 계층적 컨텍스트 관리

### Claude Code 적용
- YAML/Markdown 에이전트 정의
- 설정 기반 훅 시스템
- 프레임워크 독립적 설계

---

## 워크플로우 (Workflow)

```
사용자 입력
    |
    v
Keyword Detector --- "ulw/ultrawork" -> 병렬 모드
    |                "끝까지/완료해" -> Ralph 모드
    v
에이전트 선택
    |
    +-- opus: frontend-engineer, backend-engineer, oracle
    |        (복잡한 코드, 아키텍처, 전략)
    |
    +-- sonnet: test-engineer, librarian, explorer, document-writer
               (테스트, 조사, 탐색, 문서)
    |
    v
작업 실행 + Quality Hooks
    |
    +-- Comment Checker: 코드 편집 후 주석 검증
    +-- Todo Enforcer: 세션 종료 시 TODO 확인
```

---

## 개선부분 (Improvements)

### 1. 모델 최적화
| 작업 유형 | 모델 | 이유 |
|----------|------|------|
| 복잡한 코드 작성 | opus | 아키텍처 이해, 품질 |
| 단순 코드 작성 | sonnet | 비용 효율 |
| 정보 검색/분석 | sonnet | 충분한 성능 |
| 전략 자문 | opus | 깊은 추론 필요 |

### 2. 범용성 확보
- 프레임워크 독립 설계 (Rails, Astro, Next.js 등)
- 프로젝트별 스킬은 추후 추가 가능
- 계층적 CLAUDE.md로 프로젝트별 컨텍스트 주입

### 3. 자동화 강화
- 키워드 기반 모드 전환
- 코드 품질 자동 검증
- TODO 완료 강제

---

## 파일 위치

```
~/.claude/
+-- agents/
|   +-- oracle.md
|   +-- frontend-engineer.md
|   +-- backend-engineer.md
|   +-- test-engineer.md
|   +-- librarian.md
|   +-- explorer.md
|   +-- document-writer.md
+-- commands/
|   +-- ralph.md
|   +-- ultrawork.md
|   +-- oracle.md
+-- docs/
|   +-- hierarchical-claude-md-guide.md
+-- settings.local.json  (hooks)
```

---

## 사용 방법

### 커맨드
```
/ralph        # 자율 반복 실행 모드
/ultrawork    # 병렬 에이전트 모드
/oracle       # 전략 자문 호출
```

### 키워드 활성화
- `ulw`, `ultrawork` -> 병렬 모드
- `끝까지`, `완료해` -> Ralph 모드

---

*Generated: 2025-01-05*
