# agentic-workflow 워크플로우 가이드

## 1. 프로젝트 목적과 개요

### 목적
agentic-workflow는 Claude Code CLI를 위한 토큰 효율적인 전문 에이전트 워크플로우 시스템입니다. 복잡한 개발 작업을 자동화하면서도 토큰 사용량을 최소화하여 비용 효율적인 작업 환경을 제공합니다.

### 핵심 가치
- **토큰 효율성**: 기존 패턴 대비 최대 96% 토큰 절감
- **전문화된 에이전트**: 작업 유형별 최적화된 모델 사용
- **유연한 자동화**: 수동부터 완전 자동화까지 3단계 모드 제공
- **확장성**: 커스터마이징 가능한 에이전트, 커맨드, 훅

### 주요 특징
- 6개 전문 에이전트 (Explorer, Librarian, Architect, Frontend Engineer, Document Writer, Planner)
- 7개 슬래시 커맨드 직접 호출 인터페이스
- 자동화 훅 (키워드 감지, TODO 추적, 실패 복구)
- 3가지 작업 모드 (Manual, Semi-Auto, Ultrawork)

---

## 2. 핵심 스펙

### 에이전트 (Agents)

각 에이전트는 특정 작업에 최적화된 모델과 도구를 사용합니다.

| 에이전트 | 모델 | 주요 역할 | 사용 시점 |
|---------|------|----------|-----------|
| **Explorer** | Haiku | 코드베이스 탐색 및 병렬 검색 | 파일 찾기, 프로젝트 구조 파악 |
| **Librarian** | Sonnet | 문서 리서치 및 공식 문서 검색 | 라이브러리 사용법, 외부 자료 조사 |
| **Architect** | Opus | 아키텍처 자문 및 설계 결정 | 2회 이상 실패 시, 중요한 기술 결정 |
| **Frontend Engineer** | Opus | UI/UX 작업 및 컴포넌트 개발 | 인터페이스, 스타일링, 접근성 작업 |
| **Document Writer** | Opus | 기술 문서 작성 | README, API 문서, 코드 주석 |
| **Planner** | Opus | 작업 계획 수립 및 TODO 작성 | 복잡한 기능 구현 전 계획 단계 |

### 슬래시 커맨드 (Commands)

에이전트를 직접 호출하거나 워크플로우를 실행하는 명령어입니다.

| 커맨드 | 기능 | 사용 예시 |
|--------|------|-----------|
| `/explorer` | 코드베이스 검색 | `/explorer "인증 로직 찾아줘"` |
| `/librarian` | 문서 리서치 | `/librarian "React Query v5 사용법"` |
| `/oracle` | 전략적 자문 (Architect) | `/oracle "이 에러 해결 방법"` |
| `/frontend` | UI/UX 작업 | `/frontend "버튼 컴포넌트 만들어줘"` |
| `/plan` | 작업 계획 수립 | `/plan "사용자 인증 구현"` |
| `/execute` | 계획 실행 | `/execute` 또는 `/execute plan.md` |
| `/ultrawork` | 완전 자동화 모드 | `/ultrawork "전체 기능 구현해줘"` |

### 훅 (Hooks)

특정 이벤트에 자동으로 반응하는 스크립트입니다.

| 훅 이름 | 트리거 이벤트 | 기능 설명 |
|---------|--------------|----------|
| `keyword-detector.ps1` | UserPromptSubmit | ultrawork/ulw 키워드 감지 및 자동화 모드 활성화 |
| `todo-enforcer.ps1` | Stop | 미완료 TODO 확인 및 계속 진행 유도 |
| `ralph-loop.ps1` | Stop | 자동 반복 실행 (완료 시그널까지) |
| `failure-tracker.ps1` | PostToolUse | 반복 실패 감지 및 복구 전략 제안 |

### 작업 모드 (Operating Modes)

#### Mode 1: Manual (수동 모드)
- 특징: 직접 커맨드를 호출하여 작업 제어
- 토큰 사용량: ~500/호출
- 절감률: 기존 대비 96%
- 사용 상황: 간단한 검색, 특정 작업만 수행

#### Mode 2: Semi-Auto (반자동 모드)
- 특징: 계획 수립 → 검토 → 실행
- 토큰 사용량: ~3K/세션
- 절감률: 기존 대비 75%
- 사용 상황: 복잡한 기능, 단계적 검토 필요

#### Mode 3: Ultrawork (완전 자동화)
- 특징: 키워드로 전체 자동화 트리거
- 토큰 사용량: ~36K/세션
- 절감률: 기존 대비 67%
- 사용 상황: 전체 작업 자동화, 지속적 진행 필요

---

## 3. 워크플로우 상세 설명

### Manual 워크플로우

직접 필요한 에이전트를 호출하여 작업을 수행합니다.

```
사용자 입력
    ↓
슬래시 커맨드 실행
    ↓
해당 에이전트 작업
    ↓
결과 반환
```

**작업 흐름 예시:**
```bash
# 1. 코드 찾기
/explorer "API 라우터 위치"
→ Explorer가 병렬 검색으로 관련 파일 찾기

# 2. 문서 검색
/librarian "Prisma 트랜잭션 사용법"
→ Librarian이 공식 문서와 예제 코드 제공

# 3. UI 작업
/frontend "로그인 폼 스타일 수정"
→ Frontend Engineer가 컴포넌트 수정
```

**장점:**
- 최소 토큰 사용 (~500/호출)
- 정확한 제어
- 빠른 응답 시간

**적합한 상황:**
- 단순 검색
- 특정 작업만 수행
- 빠른 확인이 필요한 경우

---

### Semi-Auto 워크플로우

계획을 먼저 수립하고, 검토 후 실행하는 단계적 접근 방식입니다.

```
/plan 실행
    ↓
Planner가 TODO 리스트 작성
    ↓
.claude/plans/에 저장
    ↓
사용자 검토
    ↓
/execute 실행
    ↓
각 TODO를 순차 실행
    ↓
필요 시 전문 에이전트 위임
    ↓
완료
```

**작업 흐름 예시:**
```bash
# 1단계: 계획 수립
/plan "사용자 프로필 페이지 구현 (차트, 필터, 페이지네이션)"

# Planner가 다음과 같은 계획 작성:
# - [ ] API 엔드포인트 작성
# - [ ] Prisma 스키마 업데이트
# - [ ] React 컴포넌트 구현
# - [ ] 차트 라이브러리 통합
# - [ ] 필터 로직 구현
# - [ ] 페이지네이션 추가
# - [ ] 테스트 작성

# 2단계: 생성된 계획 파일 확인
# .claude/plans/user-profile-20260107.md 검토

# 3단계: 계획 실행
/execute

# 각 TODO가 순차적으로 실행되며,
# UI 작업은 Frontend Engineer에게 위임
# 문서 작업은 Document Writer에게 위임
```

**장점:**
- 체계적인 작업 관리
- 사전 검토 가능
- 적절한 토큰 사용 (~3K/세션)

**적합한 상황:**
- 복잡한 기능 구현
- 여러 단계가 필요한 작업
- 작업 순서가 중요한 경우

---

### Ultrawork 워크플로우

키워드 기반으로 전체 자동화를 트리거하는 완전 자동 모드입니다.

```
키워드 입력
(ultrawork, ulw, finish everything, complete all)
※ 한국어 키워드는 인코딩 문제로 제거됨
    ↓
keyword-detector 훅 감지
    ↓
EXPLORE 단계
  ├─ Explorer: 코드베이스 탐색
  └─ Librarian: 문서 리서치 (병렬)
    ↓
PLAN 단계
  └─ Planner: 종합 TODO 작성
    ↓
EXECUTE 단계
  ├─ 각 TODO 실행
  ├─ 필요 시 전문 에이전트 위임
  └─ failure-tracker로 실패 감지
    ↓
VERIFY 단계
  ├─ 결과 검증
  └─ 테스트 실행
    ↓
ralph-loop 훅
  ├─ 미완료 TODO 확인
  └─ 자동 재실행
    ↓
<promise>DONE</promise> 출력
    ↓
자동 종료
```

**작업 흐름 예시:**
```bash
# 키워드 입력
ulw API 라우트 작성하고 Prisma 스키마 업데이트하고 타입 생성하고 테스트 작성해줘

# 자동 실행 흐름:

# 1. EXPLORE (병렬 실행)
# - Explorer: 기존 API 구조 파악
# - Librarian: Prisma 문서 검색

# 2. PLAN
# - Planner: 종합 TODO 리스트 작성
#   - [ ] Prisma 스키마 정의
#   - [ ] 마이그레이션 실행
#   - [ ] API 라우트 핸들러 작성
#   - [ ] TypeScript 타입 생성
#   - [ ] 유닛 테스트 작성
#   - [ ] 통합 테스트 작성

# 3. EXECUTE
# - 각 TODO 자동 실행
# - 2회 실패 시 Architect에게 자문 요청

# 4. VERIFY
# - 테스트 실행
# - 결과 확인

# 5. TODO 완료 확인
# - todo-enforcer: 미완료 항목 있으면 계속 진행
# - ralph-loop: 자동 재실행

# 6. 완료
# <promise>DONE</promise>
```

**자동화 키워드:**
- `ultrawork`
- `ulw`
- `finish everything`
- `complete all`

※ 한국어 키워드 (끝까지, 완료해 등)는 PowerShell 인코딩 문제로 제거됨

**완료 시그널:**
모든 작업이 완료되면 `<promise>DONE</promise>` 출력

**장점:**
- 완전 자동화
- 지속적 진행 (Ralph Loop)
- 자동 실패 복구

**적합한 상황:**
- 전체 기능 구현
- 장시간 작업
- 반복적 작업 필요

---

## 4. 토큰 효율성 데이터

### 모드별 비교

기존 Oh My OpenCode 패턴과 비교한 토큰 사용량:

| 작업 모드 | 기존 토큰 | agentic-workflow | 절감량 | 절감률 |
|----------|----------|------------------|--------|--------|
| **Manual** | ~12,000 | ~500 | 11,500 | **96%** |
| **Semi-Auto** | ~12,000 | ~3,000 | 9,000 | **75%** |
| **Ultrawork** | ~44,000 | ~36,000 | 8,000 | **67%** |

### 효율성 이유

#### 1. 모델 최적화
- Haiku (저비용): 단순 검색 작업
- Sonnet (중간): 문서 리서치
- Opus (고성능): 복잡한 작업만

#### 2. 병렬 처리
- Explorer + Librarian 동시 실행
- 불필요한 순차 대기 제거

#### 3. 컨텍스트 관리
- 필요한 정보만 전달
- 에이전트 간 효율적 위임

#### 4. 재사용 가능한 계획
- 한 번 작성된 계획 반복 사용
- 검증된 패턴 재활용

---

## 5. 사용 시나리오 예시

### 시나리오 1: 새 라이브러리 도입

**상황:** NextAuth.js v5를 프로젝트에 추가하고 GitHub OAuth 설정

```bash
# Manual 모드
/librarian "NextAuth.js v5 GitHub OAuth 설정 방법"
```

**Librarian 작업:**
1. 공식 문서 검색
2. GitHub 예제 코드 찾기
3. 설정 가이드 정리
4. 코드 스니펫 제공

**결과:**
- 토큰 사용: ~500
- 소요 시간: 1-2분
- 공식 문서 기반 정확한 정보

---

### 시나리오 2: 코드베이스 탐색

**상황:** 결제 로직이 어디 구현되어 있는지 찾기

```bash
/explorer "결제 로직이 어디 구현되어 있어?"
```

**Explorer 작업:**
1. 병렬 파일 검색 (payment, checkout, billing 키워드)
2. 관련 함수 및 클래스 식별
3. 절대 경로와 줄 번호 제공

**결과:**
```
발견된 파일:
- c:\project\src\api\payment\stripe.ts:45
- c:\project\src\services\checkout.service.ts:89
- c:\project\src\utils\billing.helper.ts:12
```

---

### 시나리오 3: 복잡한 기능 구현

**상황:** 사용자 대시보드 페이지 구현 (차트, 필터, 페이지네이션)

```bash
# Semi-Auto 모드

# 1. 계획 수립
/plan "사용자 대시보드 페이지 구현 (차트, 필터, 페이지네이션)"
```

**Planner가 작성한 계획:**
```markdown
# 사용자 대시보드 구현 계획

## TODO
- [ ] 백엔드 API 엔드포인트 작성
  - 사용자 통계 데이터 API
  - 필터링 로직 구현
  - 페이지네이션 쿼리

- [ ] 프론트엔드 컴포넌트
  - Dashboard 레이아웃 컴포넌트
  - Chart 컴포넌트 (recharts 사용)
  - Filter 컴포넌트
  - Pagination 컴포넌트

- [ ] 데이터 통합
  - React Query 설정
  - 상태 관리
  - 로딩/에러 처리

- [ ] 테스트
  - API 테스트
  - 컴포넌트 테스트
```

```bash
# 2. 계획 검토 후 실행
/execute
```

**Execute 작업:**
- Backend 작업: 기본 에이전트
- Frontend 작업: Frontend Engineer에게 위임
- 문서 작업: Document Writer에게 위임

**결과:**
- 토큰 사용: ~3,000
- 체계적 구현
- 검토 가능한 단계

---

### 시나리오 4: 전체 자동화

**상황:** API부터 테스트까지 전체 기능 구현

```bash
ulw 사용자 인증 API 작성하고 Prisma 스키마 업데이트하고 타입 생성하고 테스트 작성해줘
```

**자동 실행 흐름:**

**1. EXPLORE**
- Explorer: 기존 인증 구조 확인
- Librarian: NextAuth/JWT 문서 검색

**2. PLAN**
```markdown
- [ ] Prisma User 모델 정의
- [ ] 인증 미들웨어 작성
- [ ] /api/auth/* 라우트 작성
- [ ] JWT 토큰 발급/검증 로직
- [ ] TypeScript 타입 정의
- [ ] 유닛 테스트
- [ ] 통합 테스트
```

**3. EXECUTE**
- 각 TODO 순차 실행
- 실패 시 Architect 자문
- Ralph Loop로 자동 재실행

**4. VERIFY**
- 테스트 실행
- 결과 검증

**5. 완료**
```
<promise>DONE</promise>
```

**결과:**
- 토큰 사용: ~36,000
- 완전 자동화
- 검증까지 완료

---

### 시나리오 5: 버그 해결

**상황:** 복잡한 버그를 여러 방법으로 시도했지만 해결 안 됨

```bash
# 첫 시도
"이 버그 고쳐줘"
→ 실패

# 두 번째 시도
"다른 방법으로 시도해줘"
→ 실패
```

**failure-tracker 훅 감지:**
2회 이상 반복 실패 감지

```bash
# 자동으로 Architect 자문 제안
/oracle "이 방법들을 시도했는데 안 됩니다:
1. 캐시 초기화
2. 의존성 재설치
3. 설정 파일 수정
다른 접근법을 추천해주세요"
```

**Architect 작업:**
1. 시도한 방법 분석
2. 근본 원인 파악
3. 대안적 접근법 제시
4. 아키텍처 관점의 해결책

**결과:**
- 반복 실패 방지
- 전략적 접근
- 근본 원인 해결

---

## 6. 실전 활용 팁

### 1. 모드 선택 가이드

**Manual 사용:**
- 단순 검색이 필요할 때
- 빠른 확인이 필요할 때
- 토큰 절약이 중요할 때

**Semi-Auto 사용:**
- 여러 단계 작업일 때
- 검토가 필요할 때
- 체계적 접근이 중요할 때

**Ultrawork 사용:**
- 전체 기능 구현이 필요할 때
- 시간을 절약하고 싶을 때
- 지속적 진행이 필요할 때

### 2. 에이전트 활용 전략

**검색 우선:**
작업 전 Explorer와 Librarian으로 정보 수집

**전문가 위임:**
복잡한 UI는 Frontend Engineer에게, 문서는 Document Writer에게

**실패 시 자문:**
2회 이상 실패하면 Architect에게 전략 요청

### 3. TODO 관리

**명확한 TODO 작성:**
- 구체적이고 측정 가능한 작업 단위
- 의존성 명시
- 우선순위 표시

**TODO 추적:**
- todo-enforcer가 자동으로 미완료 항목 알림
- 완료 시그널로 자동 종료

---

## 결론

agentic-workflow는 Claude Code의 강력한 기능을 최대한 활용하면서도 토큰 효율성을 극대화한 워크플로우 시스템입니다.

**핵심 장점:**
- 96% 토큰 절감 (Manual 모드)
- 전문화된 에이전트 시스템
- 유연한 자동화 레벨
- 확장 가능한 아키텍처

**시작하기:**
```bash
git clone https://github.com/YOUR-USERNAME/agentic-workflow.git
cd agentic-workflow
./install.sh
```

프로젝트의 복잡도와 요구사항에 맞는 모드를 선택하여 효율적으로 개발을 진행하세요.
