# agentic-workflow — 이 저장소에서 작업할 때

> 이 파일은 **이 저장소의 기여자용** 지침이다. 사용자 환경에는 배포되지 않는다.
> Maestro 의 절대 규칙은 `skills/maestro/SKILL.md` 맨 위, 규약의 정본은 `skills/maestro/WORKFLOW.md` 다. v5.5.0 부터 `~/.claude/rules/` 로는 아무것도 배포하지 않는다.

---

## 이 저장소가 배포하는 것

| 배포 | 대상 |
|---|---|
| `skills/maestro/` · `skills/duet/` | `~/.claude/skills/` |
| `agents/*.md` · `hooks/*` | `~/.claude/` 각 디렉터리 |

**`~/.claude/CLAUDE.md` 와 `~/.claude/rules/` 는 건드리지 않는다.** 그 자리는 사용자 것이고, 거기 놓인 것은 매 세션 전부 로드된다. 마에스트로 규칙은 `/maestro` 런에서만 의미가 있으므로 스킬 안에 둔다(`disable-model-invocation` — 설명문도 컨텍스트에 안 실린다). 룰을 다시 배포해야 할 일이 생기면 install 의 allowlist 로 이름을 적어 넣는다 — glob 금지.

코딩 규율·보안 정책·메모리 규약처럼 상시 적용되는 것은 **배포 대상이 아니다** — 사람마다 다르고 시한부인 경우도 있다. 각자의 `rules/` 에 둔다.

---

## ⚠️ 이 저장소를 고칠 때

**워킹트리가 곧 라이브 설정이다.** 심볼릭 링크 배포라 복사 시절의 완충이 없다.

- `skills/` 나 `hooks/` 를 고치면 **스킬과 가드 훅이 그 즉시 바뀐다** — 실행 중인 모든 세션·모든 프로젝트에서
- 브랜치 전환 · `stash` · `reset --hard` 도 마찬가지다. 실험용 브랜치는 별도 클론(또는 worktree)에서
- 브랜치를 옮긴 뒤에는 `./install.sh` 를 다시 실행한다 — 추가·삭제된 파일의 링크를 맞춘다

**설치 스크립트는 실제 `$HOME` 에 대고 테스트하지 않는다.**

```bash
HOME=/tmp/fake-$$ ./install.sh     # 가짜 홈에 개인 룰·훅·스킬을 심어두고 생존을 확인
```

---

## 검증

변경 후 아래를 돌린다:

```bash
for f in install.sh uninstall.sh hooks/*.sh; do bash -n "$f" || echo "FAIL $f"; done
for f in install.ps1 uninstall.ps1 hooks/*.ps1; do
  pwsh -NoProfile -Command "\$e=\$null;[void][System.Management.Automation.Language.Parser]::ParseFile('$PWD/$f',[ref]\$null,[ref]\$e);if(\$e.Count){'FAIL $f'}"
done
python3 -c "import json;json.load(open('settings.json'))"
bash tests/hooktest.sh hooks    # 훅(maestro-guard · compact-reload · verify-prompt)을 고쳤을 때 — 동작 표 132칸
```

`AGENTS.md` 는 **생성물이다** — 손으로 고치지 않는다. `CLAUDE.md` 를 고치면 `hooks/claude-md-sync.sh` 가 재생성한다. 첫 줄의 `<!-- maestro-codex: sync-from-claude -->` 는 Maestro Codex 동기화 opt-in 이며, `diff CLAUDE.md AGENTS.md` 가 헤더 3줄만 보여야 정상이다. 동기화는 `CLAUDE.md` 본문만 복사하고 `~/.claude/rules/` 로딩 지시는 추가하지 않는다. 그 전역 규칙은 Claude Code 전용이며 Codex 지침과 충돌할 수 있다.

---

## 무엇이 여기 속하는가

공개 저장소 편입 기준 4항 — 하나라도 걸리면 대상이 아니다:

1. 특정 사용자에게만 맞춘 커스터마이징
2. 특정 기술 스택·로케일 한정
3. 보안·유출 소지
4. 로컬 전용 민감 정보

판단축은 관리 편의가 아니라 **대상 독자**다. 이 저장소는 *maestro 라는 오케스트레이션 워크플로우* 하나를 배포한다.

---

*변경 이력 → `CHANGELOG.md` · 마이그레이션 → `docs/migrations.md`*
