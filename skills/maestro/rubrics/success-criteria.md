# Success Criteria Rubric — Phase 6 VERIFY

> Phase 6 는 **success criteria sign-off 전용**이다. 테스트는 5b/5c 에서 이미 끝났다 — 여기서 테스트를 다시 돌리는 건 Phase 6 가 아니라 5c 의 반복이다.
> 검증자(verifier agent)가 이 표에 채워 넣는다.

## 입력

- plan 의 `### Success Criteria` 체크리스트
- 5b worker self-test 출력 (axis 별)
- 5c 풀 스위트 결과 + `5c anomaly:` 라인 (있으면)
- 5d Reviewer / Codex#2 / 시각 axis 결과
- `git diff` (실제 변경분)

## 채점 항목

| # | 항목 | PASS 기준 |
|---|---|---|
| S1 | criteria 커버리지 | plan 의 각 success criterion 이 **어느 산출물로** 충족됐는지 1:1 로 지목됨. "전반적으로 됨" 은 FAIL |
| S2 | 근거의 실재성 | 각 주장이 실행 결과(테스트 출력·렌더·수동 확인)에 근거. 코드 판독만으로 단정한 항목은 `unverified` 로 분리 표기 |
| S3 | 범위 정합 | diff 가 plan 범위 안. 요청 밖 변경이 있으면 목록화 |
| S4 | 회귀 부재 | 5c 결과가 baseline 대비 회귀 없음. anomaly accept 가 있었다면 그 사유가 구체적 수치를 포함 |
| S5 | 미해결 항목 노출 | known_gaps · 기각된 finding · 미수행 axis 가 **사용자 summary 에 드러남** (조용히 사라진 항목 없음) |
| S6 | 되돌릴 수 있는가 | 변경이 단일 커밋/브랜치로 회수 가능. 되돌리기 어려운 조치(마이그레이션·외부 반영)가 있으면 명시 |

## 출력 계약

```
verify: <PASS | FAIL>
S1..S6: <각 항목 판정 한 줄>
criteria:
  - <criterion> → <충족 근거> [verified | unverified]
unresolved: <미해결/기각/미수행 목록 — 없으면 "none">
```

**FAIL 이면 무엇을 더 하면 PASS 인지**까지 적는다. 판정만 던지고 끝내지 않는다.
