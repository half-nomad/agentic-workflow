---
description: 병렬 에이전트 오케스트레이션 - 최대 속도로 복잡한 작업 수행
---

# Ultrawork Mode

최대 병렬성으로 여러 전문 에이전트를 동시에 활용합니다.

## Phase 1: 병렬 탐색

다음 3개 Task를 **동시에 병렬 실행**하세요:

1. **Explore #1 - 구조 파악**
   - subagent_type: Explore
   - 프로젝트 전체 구조와 주요 디렉토리 파악
   - 진입점 파일 식별

2. **Explore #2 - 관련 파일 검색**
   - subagent_type: Explore
   - 작업 대상과 관련된 파일들 검색
   - 키워드, 패턴 기반 탐색

3. **Explore #3 - 테스트/설정 분석**
   - subagent_type: Explore
   - 테스트 파일 구조 파악
   - 설정 파일 (config, env) 확인

## Phase 2: 전략 수립

- Plan 에이전트 (opus 모델) 사용
- Phase 1 결과 종합하여 구현 전략 설계
- 병렬 가능한 작업과 순차 작업 분류

## Phase 3: 병렬 구현

독립적인 작업은 **동시에 병렬 실행**:
- Frontend 작업 -> frontend-engineer 에이전트
- Backend 작업 -> backend-engineer 에이전트
- 의존성 있는 작업은 순차 실행

## Phase 4: 검증

- test-engineer 에이전트로 테스트 실행
- 빌드 확인
- 린트 검사

## 완료 조건

- 모든 TODO 항목 completed
- 모든 테스트 통과
- 빌드 성공

## 별칭

/ulw

---

$ARGUMENTS