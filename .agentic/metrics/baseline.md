# Baseline Metrics

**Date**: 2026-01-11
**Version**: 1.0
**Purpose**: Establish baseline measurements before implementing Anthropic patterns

---

## Current Performance Metrics

### Task Completion

| Metric | Current Value | Target | Measurement Method |
|--------|---------------|--------|-------------------|
| Task completion rate | TBD% | >95% | Count of tasks reaching `<promise>DONE</promise>` / Total tasks |
| First-try success rate | TBD% | >85% | Tasks succeeding without @architect escalation |
| Failure escalation rate | TBD% | <15% | Tasks requiring 2+ retries |

### Token Efficiency

| Metric | Current Value | Target | Measurement Method |
|--------|---------------|--------|-------------------|
| Tokens per simple task (Level 1-2) | TBD | -30% | Average tokens for single-file changes |
| Tokens per complex task (Level 5-7) | TBD | -15% | Average tokens for multi-file features |
| Agent delegation overhead | TBD | <10% | Tokens spent on routing vs execution |

### Execution Time

| Metric | Current Value | Target | Measurement Method |
|--------|---------------|--------|-------------------|
| Simple task duration | TBD min | -50% | Time from input to DONE (Level 1-2) |
| Complex task duration | TBD min | -30% | Time from input to DONE (Level 5-7) |
| Parallel vs sequential ratio | TBD | 3:1 | Concurrent agent calls / Sequential calls |

### Quality Indicators

| Metric | Current Value | Target | Measurement Method |
|--------|---------------|--------|-------------------|
| Phase gate failures | N/A | <20% | EXPLORE/PLAN/EXECUTE/VERIFY gate rejections |
| Rework rate | TBD% | <10% | Tasks requiring revision after VERIFY |
| User override frequency | TBD% | <5% | Manual intervention during Ultrawork |

---

## Measurement Protocol

### Data Collection

1. **Session Logging**: Enable `.agentic/logs/` for all Ultrawork sessions
2. **Token Tracking**: Record input/output tokens per agent call
3. **Timing**: Log timestamps at phase transitions
4. **Outcomes**: Track DONE signal presence and retry counts

### Collection Period

- **Baseline Period**: 2 weeks before Phase 1 implementation
- **Comparison Period**: 2 weeks after each phase completion
- **Final Assessment**: 4 weeks after Phase 4 completion

### Sampling Criteria

| Task Type | Minimum Samples | Notes |
|-----------|-----------------|-------|
| Simple (Level 1-2) | 20 | Single file, direct answer |
| Moderate (Level 3-4) | 15 | Multi-file, standard Sisyphus |
| Complex (Level 5-7) | 10 | Full pipeline with evaluation |

---

## Rollback Triggers

If any metric degrades beyond threshold, rollback is triggered:

| Metric | Rollback Threshold | Action |
|--------|-------------------|--------|
| Task completion rate | <70% (vs baseline) | Disable Task Router |
| Token usage | >150% increase | Disable Evaluator Loop |
| Execution time | >200% increase | Disable Parallel Execution |
| User overrides | >30% frequency | Revert to Manual mode default |

### Rollback Procedure

1. **Immediate**: Set feature flag to `false` in `.agentic/config.yaml`
2. **Logging**: Record failure conditions in `.agentic/metrics/rollback-log.md`
3. **Analysis**: Identify root cause before re-enabling
4. **Re-enable**: Gradual rollout with 25% -> 50% -> 100% traffic

---

## Status

- [ ] Baseline data collection started
- [ ] 2-week collection period completed
- [ ] Baseline values recorded above
- [ ] Ready for Phase 1 implementation

---

*Template created: 2026-01-11*
*Last updated: 2026-01-11*
