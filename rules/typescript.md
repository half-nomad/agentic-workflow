---
paths:
  - "**/*.ts"
  - "**/*.tsx"
description: "TypeScript conventions that differ from the obvious default"
---

# TypeScript Rules

> `strict: true`, `any` 회피, optional chaining, `Promise.all`, import 그룹핑 같은 건 적지 않는다 — 모델 기본값이고, 다시 적으면 상충 지시만 늘어난다. 아래는 **취향이 갈리는 지점**만.

- **Named exports only.** `export default` 금지 — re-export 와 자동 import 일관성 때문.
- **Public 함수는 반환 타입 명시.** 내부 헬퍼는 추론에 맡겨도 된다.
- **`unknown` over `any`** — 좁힐 수 없으면 타입 가드를 쓰고, `any` 를 쓸 땐 이유를 한 줄 남긴다.
- **에러는 클래스로.** 호출부가 분기해야 하는 실패는 `Error` 서브클래스 (`name` 설정 + 판별 필드) 로 던진다. 문자열 매칭 금지.
- **비-널 단언(`!`) 금지** — 좁히기로 대체한다.
