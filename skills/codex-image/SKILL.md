---
name: codex-image
description: Generate high-quality images via Codex's built-in image tool with automatic prompt enhancement. Use this skill whenever the user wants to create, generate, draw, or make any kind of image, picture, illustration, photo, artwork, or visual — including phrases like "이미지 만들어줘", "그림 그려줘", "사진 생성", "make an image", "draw a", "generate a picture", or any visual creation request, even when the user gives only a one-line description. The skill expands brief requests into detailed prompts (subject, style, composition, lighting, mood, aspect ratio) before delegating to the Codex companion CLI (`codex-companion.mjs task --write --cwd`), which calls Codex's internal `imagegen` skill (no OpenAI API key needed) and saves output to a context-aware path. Do NOT use the OpenAI API directly — always go through Codex's built-in image tool.
---

# Codex Image Generator

Generate images by enhancing a user's brief request into a model-friendly prompt, then delegating execution to Codex's built-in `imagegen` skill through a direct `codex-companion` CLI call.

## Why this skill exists

Image models reward concrete visual language. "고양이 그려줘" produces generic output; the same intent expanded with breed, lighting, style, composition, and mood produces dramatically better results. The user's job is intent; this skill's job is to translate intent into the visual vocabulary the model responds to — and then route the actual generation through the right execution path (Codex internal tool, not OpenAI API key).

## How Codex's `imagegen` skill actually saves files

Important — Codex's built-in `image_gen` tool does NOT accept a destination-path argument. It always saves to:

```
$CODEX_HOME/generated_images/{session_id}/ig_{hash}.png
```

To put the file where the user wants, the workflow is **generate first, then move/copy**. This skill embeds that move into the Codex delegation prompt so the user sees only the final path.

## Workflow

### 1. Parse the user's request

Extract whatever is present:
- **Subject** — what to draw
- **Style** — photo, illustration, 3D, anime, painting (if mentioned)
- **Aspect ratio** — explicit ratio or hints like "썸네일", "세로형"
- **Aesthetic references** — "지브리 느낌", "사이버펑크" 등
- **Reference image** — user-uploaded image (see edge cases)
- **Transparency** — "투명 배경", "transparent background" (see Transparent backgrounds)

If the user request is shorter than ~30 words AND fewer than 2 of {style, mood, composition} are inferable, ask ONE clarifying question via AskUserQuestion (skip when `--auto` flag is present). Limit to ONE round — don't interrogate.

### 2. Strip flags from the prompt text

Recognize and remove these flags before processing:

- `--auto` — Skip the prompt-confirmation step in step 5
- `--raw` — Skip enhancement entirely; pass user's text verbatim
- `--ko` — Keep enhanced prompt in Korean (default: translate to English)
- `--ratio <value>` — e.g. `--ratio 16:9` or `--ratio 1:1`
- `--style <value>` — e.g. `--style photo`, `--style anime`
- `--out <path>` — Override save path (default: context-aware resolution in step 4)
- `--transparent` — Request transparent background (chroma-key path; see Transparent backgrounds)

Important — flags are **not** tool arguments. Codex's internal `image_gen` tool exposes only a single callable argument: `prompt`. There is no `size`, `quality`, `style`, `n`, or `background` parameter. So `--ratio` / `--style` / `--transparent` must be **fused into the enhanced prompt text** in step 3, not passed as separate arguments. Examples:

- `--ratio 16:9` → append "16:9 widescreen aspect ratio" to the prompt
- `--style photo` → ensure the style descriptor in the prompt body resolves to photographic ("editorial DSLR photograph, 50mm lens, …")
- `--transparent` → swap the background clause for "solid pure magenta (#FF00FF) chroma-key background, no gradient, no shadows, subject fully separated" (see Transparent backgrounds for post-processing)

### 3. Enhance the prompt

Read `references/prompt-guide.md` and apply the checklist. Default to **English output** because most image models perform better in English; only keep Korean if `--ko` flag is set.

Skip enhancement when:
- `--raw` flag is present
- User input already contains 30+ words of concrete visual detail (subject + style + composition + lighting at minimum)

The enhanced prompt should be one paragraph, ~50-120 words, structured roughly as:

```
[Subject + key attributes], [setting/context], [style descriptor], 
[composition/angle], [lighting], [color palette], [mood/atmosphere], 
[quality cues], [aspect ratio].
```

### 4. Resolve save path (context-aware)

Pick destination by these rules in order:

1. **`--out <path>` flag present** → use that path verbatim.
2. **Inside a git repo + an `images/` dir exists beside the cwd's content folder** → put it there (`{that folder}/images/{slug}.png`), so generated assets land next to the content that uses them.
3. **Inside a git repo (other paths)** → `{repo_root}/outputs/imagegen/{slug}.png`.
4. **Outside a git repo** → `~/Downloads/{slug}.png`.

Determine git repo root with `git rev-parse --show-toplevel` (silently fall through to the last rule on error).

> Projects with their own asset conventions should override this by defining the target layout in the project's `CLAUDE.md` — this skill only supplies the fallback.

### 5. Confirm with the user (default) or auto-execute

Show the enhanced prompt and the resolved save path, then ask the user to approve, edit, or regenerate. Skip this step if:
- `--auto` flag is set
- User clearly said "그냥 만들어줘" / "just generate it"

Format:
```
**Enhanced prompt:**
[full enhanced prompt]

**Save to:** {resolved_path}

Approve? (yes / edit / regenerate)
```

### 6. Delegate to Codex

**Sandbox rule — two separate constraints.** The image always generates; only the *move* fails, and it fails **silently**. Both are required:

1. **`--write`** — without it the sandbox is read-only and cannot move the file out of `$CODEX_HOME/generated_images/...`.
2. **`--cwd <destination parent>`** — `--write` alone only unlocks the *current workspace*. A destination outside it is denied even with `--write`. Measured: `~/Downloads` → **DENIED** when cwd was elsewhere, **WROTE** with `--cwd "$HOME/Downloads"`.

Constraint 2 is why this skill calls the companion **directly** rather than through the `codex:codex-rescue` subagent — the subagent cannot forward `--cwd`, so it is locked to the session repo and cannot save anywhere outside it. It also costs ~31k tokens per image (`CLAUDE.md` §Codex 직접 호출).

**Copy, not move.** The original at `$CODEX_HOME/generated_images/...` **cannot be deleted** — that path sits outside the `--cwd` workspace, so the sandbox refuses removal. Asking Codex to "move" makes it report a refused deletion step and fall back to copying anyway. Every generated image therefore exists twice — prune `$CODEX_HOME/generated_images/` periodically, since it accumulates unbounded.

If the user explicitly demands read-only behavior, warn them: the generated file will stay at `$CODEX_HOME/generated_images/{session_id}/ig_{hash}.png` and they'll have to copy it out manually.

Tell Codex to use its **built-in `image_gen` tool** AND embed the copy to the resolved path. Substitute `{resolved_path}` and `{enhanced_prompt}` before running:

```bash
CX=$(ls -d ~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs | tail -1)
DEST_DIR=$(dirname "{resolved_path}")
mkdir -p "$DEST_DIR"
REQ=$(mktemp)   # --prompt-file, never `task "..."` — a single argument is re-tokenized and loses quotes/newlines
cat > "$REQ" <<'PROMPT'
OpenAI API를 사용하지 말고, Codex 자체 기능(내장 image_gen 도구) 으로
아래 프롬프트로 이미지를 생성한 후, 자동 저장된 파일을
{resolved_path} 로 복사해줘. 원본은 샌드박스 권한상 삭제할 수 없으니 삭제는 시도하지 마라.

이미지 프롬프트:
{enhanced_prompt}

완료 후 최종 절대경로 + 파일 크기 (bytes) 를 한 줄로 보고.
PROMPT
node "$CX" task --write --cwd "$DEST_DIR" --skip-git-repo-check --prompt-file "$REQ"
```

Why this phrasing: in earlier sessions, asking for "gpt-image-1 모델" or just "이미지 생성" caused Codex to look for `OPENAI_API_KEY`. The phrase "Codex 자체 기능(내장 image_gen 도구)" reliably triggers the internal `imagegen` skill path. The explicit move instruction prevents the asset stranded at the default `$CODEX_HOME/generated_images/...` location.

### 7. Verify the output

Before reporting success, run:

```bash
[ -s "{resolved_path}" ] && file "{resolved_path}" | grep -qi "image" \
  && echo "OK: $(stat -f '%z bytes' '{resolved_path}')" \
  || echo "FAIL"
```

If FAIL, surface the Codex stdout to the user and ask whether to retry (do not silently swallow the failure).

### 8. Save prompt sidecar (auto)

Write `{resolved_path%.png}.prompt.md` next to the image with metadata:

```markdown
# {slug}
Generated: {ISO 8601 timestamp}
Save path: {resolved_path}

## User request
{verbatim original input}

## Enhanced prompt
{the prompt sent to Codex}

## Flags
{any --flags used, or "(none)"}

## Source
codex-image skill → codex-companion CLI (task --write --cwd) → Codex built-in image_gen
```

Reason: when the user wants to iterate the same image weeks later, the sidecar is the only durable record of the prompt used. Without it, regeneration requires digging chat history.

Skip the sidecar only when the user passed `--no-sidecar` or saved path is under `~/Downloads/` (transient location).

### 9. Report results

After verification, confirm to the user:
- Final saved path
- File size
- Sidecar path (if written)
- The enhanced prompt (so they can iterate)
- A one-line note on what changed if the user asked for a regeneration

## Slug naming

Derive `{slug}` from the subject in 2–4 kebab-case English words. When the destination folder implies a role, prefix accordingly:

| Context | Pattern | Example |
|---------|---------|---------|
| Content folder with an `images/` dir | `{content-slug}-{role}` | `spring-launch-guide-hero` |
| Blog-style content | `blog-{post-slug}-{role}` | `blog-2026-spring-launch-cover` |
| Social/SNS content | `sns-{platform}-{slug}` | `sns-instagram-cherry-blossom` |
| `outputs/imagegen/` (generic) | `{domain}-{subject}` | `docs-architecture-diagram` |
| `~/Downloads/` (no repo context) | `{subject}` | `ginger-tabby-cat` |

Avoid generic slugs like `image-1` or `output`. The slug is what the user sees in their file browser weeks later.

## Multiple images / variations

If the user asks for variations or multiple images:
- Generate one at a time, sequentially (each requires a separate Codex call — Codex's built-in path issues one `image_gen` call per asset; there is no `n` parameter on the built-in tool)
- Vary one axis per attempt (lighting OR composition OR mood — not all at once)
- Use slug suffixes: `cyberpunk-night-cityscape-v1.png`, `-v2.png`
- Each variation gets its own sidecar file

## Transparent backgrounds

Codex's built-in `image_gen` tool does NOT support native transparency (`background=transparent`). Two paths:

### Path A — chroma-key + local helper (preferred, no API key)

1. Enhance the prompt to include a flat removable backdrop: `solid pure magenta (#FF00FF) background, no gradient, no shadows, subject fully separated from background`.
2. Generate normally via step 6.
3. Add a post-process step to the Codex delegation prompt:
   ```
   생성 후, $CODEX_HOME/skills/.system/imagegen/scripts/remove_chroma_key.py
   helper 로 chroma key (#FF00FF) 를 제거하고 PNG with alpha 로 {resolved_path} 에 저장.
   ```
4. Verify alpha channel: `sips -g hasAlpha "{resolved_path}" | grep -q "yes"` (macOS) or equivalent.

### Path B — CLI fallback with `gpt-image-1.5` (requires API key + explicit user approval)

True native transparency requires the CLI fallback path. This:
- Requires `OPENAI_API_KEY` set
- Is **NOT default behavior** — must be explicitly confirmed by the user
- Uses Codex's `scripts/image_gen.py` with `gpt-image-1.5 --background transparent --output-format png`

Only proceed with Path B after the user explicitly says yes. Tell them about the API key requirement first.

## Edge cases

- **User uploads a reference image**: Codex's built-in `image_gen` can edit images that are visible in the conversation context. Process: (1) ask Codex to call its `view_image` tool on the reference first, (2) then run `image_gen` in edit mode with the prompt describing the desired transformation. Embed both steps in the `--prompt-file` text. Local file paths must go through `view_image` — built-in edit cannot accept arbitrary filesystem paths directly.
- **NSFW / restricted content**: Decline politely. The internal tool already filters but don't waste a Codex call on it.
- **User wants a specific real person's likeness**: Decline for living public figures. Generic "businesswoman in suit" style descriptions are fine.
- **Prompt is in a third language (not Korean/English)**: Translate to English for the model, but mirror the user's reply language in your messages.
- **Save path already exists**: Append `-v2`, `-v3`, etc. before the extension. Do not overwrite unless the user explicitly asked for replacement.

## What NOT to do

- Do NOT call the OpenAI Images API or ask the user for an API key (except Path B above with explicit approval)
- Do NOT try to use Bash + `curl` to hit any endpoint
- Do NOT generate the image yourself with any other tool — always route through the `codex-companion` CLI call above
- Do NOT skip the enhancement step silently when the prompt is short — either enhance, or explicitly note `--raw` is in effect
- Do NOT promise a destination path to the built-in `image_gen` tool — it ignores destination args. Always rely on the post-generation copy embedded in the Codex prompt.
- Do NOT leave a project-bound asset available *only* at `$CODEX_HOME/generated_images/...` — the copy step in workflow §6 is mandatory for paths resolved via rules §4.2–§4.4. (The original always remains there; that is expected — see §6.)
- Do NOT instruct Codex to `move`/delete the original — the sandbox denies it and the refusal shows up as a scary-looking failure line in the run log.
