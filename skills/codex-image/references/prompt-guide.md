# Image Prompt Enhancement Guide

A reference checklist for transforming brief user requests into detailed prompts that image models respond well to. Read this whenever expanding a prompt in the `codex-image` skill.

## Core Components (assemble in this order)

| # | Component | Purpose | Example |
|---|-----------|---------|---------|
| 1 | **Subject** | Concrete noun + key attributes | "a fluffy ginger tabby cat" |
| 2 | **Setting / Context** | Where/when | "sitting on a wooden windowsill, autumn afternoon" |
| 3 | **Style** | Pick ONE primary | "watercolor illustration" |
| 4 | **Composition** | Angle, framing, focus | "medium close-up, slight Dutch angle, shallow depth of field" |
| 5 | **Lighting** | Time of day, source, quality | "soft golden-hour backlight through sheer curtains" |
| 6 | **Color Palette** | Dominant colors | "warm peach, cream, and amber tones" |
| 7 | **Mood / Atmosphere** | Emotional register | "cozy, serene, contemplative" |
| 8 | **Quality Cues** | Render quality | "ultra-detailed fur texture, cinematic" |
| 9 | **Aspect Ratio** | At the end | "4:3 aspect ratio" |

A good prompt usually hits 6–8 of these. Don't pad — every clause should add visual signal.

## Style Vocabulary

Choose ONE primary style, then add 1–2 supporting cues.

### Photography
- Base: `photorealistic`, `DSLR shot`, `editorial photo`, `documentary style`
- Camera: `shot on Sony A7R`, `35mm`, `85mm portrait lens`, `macro lens`
- Effects: `shallow depth of field`, `bokeh background`, `film grain`, `Kodak Portra 400`

### Digital Illustration
- `digital illustration`, `concept art`, `flat vector art`, `editorial illustration`
- Artist-style refs (use sparingly): `studio ghibli inspired`, `moebius style`

### 3D Render
- `octane render`, `blender 3D`, `cinema 4D`, `unreal engine 5`
- Sub-styles: `low-poly`, `isometric`, `claymation`, `voxel art`

### Anime / Manga
- `anime key visual`, `cel-shaded`, `manga panel`, `90s anime aesthetic`
- Studio cues: `studio ghibli style`, `makoto shinkai style` (atmospheric backgrounds)

### Painting
- `oil painting`, `watercolor`, `gouache`, `acrylic on canvas`
- Movements: `impressionist`, `art nouveau`, `renaissance`, `ukiyo-e`

## Composition Terms

### Shot Type
- `close-up` / `extreme close-up` / `medium shot` / `wide shot` / `establishing shot`
- `aerial view` / `drone shot` / `bird's eye view` / `worm's eye view`

### Angle
- `low angle looking up` (heroic/imposing)
- `high angle looking down` (vulnerability/overview)
- `Dutch angle` (tension)
- `eye-level` (neutral, intimate)

### Framing
- `centered composition` / `rule of thirds` / `leading lines toward [X]`
- `symmetrical` / `asymmetric` / `negative space on the left`

### Focus
- `sharp focus throughout` / `shallow depth of field with background blur`
- `tilt-shift miniature effect`

## Lighting Vocabulary

### Time / Source
- `golden hour` (warm, low-angle, ~30 min before sunset)
- `blue hour` (cool, after sunset, before dark)
- `overcast daylight` (soft, even, no harsh shadows)
- `harsh midday sun` (strong shadows, high contrast)
- `moonlit` / `candlelit` / `firelight` / `neon-lit`

### Quality
- `soft diffused light` / `hard directional light`
- `volumetric lighting` (visible light rays / god rays)
- `chiaroscuro` (strong light/dark contrast, Renaissance-style)
- `rim lighting` / `backlit silhouette` / `side-lit`

### Mood Lighting
- `moody and dramatic` / `bright and airy` / `dim and intimate`

## Color Palette Patterns

Specify 2–4 dominant colors. Useful pairings:
- **Cinematic**: `teal and orange`
- **Cyberpunk**: `magenta and cyan with deep black`
- **Cozy**: `warm peach, cream, and burnt sienna`
- **Nordic**: `cool blue-grey, white, muted green`
- **Sunset**: `golden yellow, coral pink, lavender`
- **Monochrome**: `desaturated`, `black and white`, `sepia tone`

## Mood / Atmosphere Words

Pick 1–2 that match intent:
`serene` · `melancholic` · `whimsical` · `ominous` · `nostalgic` · `dreamlike` · `tense` · `peaceful` · `energetic` · `contemplative` · `mysterious` · `triumphant` · `intimate` · `vast`

## Quality Cues

Use sparingly — these are tail-end boosters, not substitutes for content.

- `ultra-detailed` / `intricate detail` / `hyper-detailed`
- `cinematic` / `editorial quality` / `award-winning photograph`
- `8k` / `4k` (mostly placebo but harmless)
- `professional studio lighting` / `magazine cover quality`

Avoid stacking too many. Two is plenty.

## Aspect Ratios

Place at the end of the prompt. Common choices:

| Ratio | Use Case |
|-------|----------|
| `1:1` | Instagram square, profile pic, stickers |
| `16:9` | YouTube thumbnail, presentation slide, desktop wallpaper |
| `9:16` | Instagram story, TikTok, mobile wallpaper, vertical poster |
| `4:3` | Classic photo, magazine illustration |
| `3:2` | DSLR landscape, print photo |
| `2:3` | Book cover, vertical portrait |
| `21:9` | Cinematic widescreen, banner |

## Negative Cues (when needed)

If the user has shown sensitivity to specific failure modes, append:
```
Avoid: text, watermarks, distorted hands, low resolution, oversaturation, extra limbs.
```

Don't add this by default — it lengthens the prompt without need.

## Korean → English Translation Tips

Translate the noun/adjective skeleton; preserve cultural specifics in romanized form with a brief gloss.

| Korean | English |
|--------|---------|
| 사이버펑크 도시 | cyberpunk megacity |
| 아늑한 카페 | cozy cafe interior |
| 수채화 느낌 | watercolor style |
| 실사 / 사실적 | photorealistic |
| 일러스트 | digital illustration |
| 야경 | night cityscape |
| 새벽 | dawn / pre-dawn |
| 노을 | sunset glow / golden hour |
| 분위기 있는 | atmospheric / moody |
| 따뜻한 | warm-toned |
| 미니멀 | minimalist |
| 한복 입은 여성 | a woman in hanbok (traditional Korean dress) |
| 떡볶이 | tteokbokki (Korean spicy rice cakes) |

## Example Transformations

### Example 1 — Cat
**Input**: "고양이 그려줘"

**Enhanced**:
> A fluffy ginger tabby cat sitting on a wooden windowsill, soft afternoon sunlight filtering through sheer linen curtains, watercolor illustration style with visible brush textures, medium close-up at eye level with shallow depth of field, warm peach and cream color palette accented with amber, cozy and serene mood, ultra-detailed fur texture, 4:3 aspect ratio.

### Example 2 — Cyberpunk
**Input**: "사이버펑크 야경"

**Enhanced**:
> A sprawling cyberpunk megacity at night, neon-lit skyscrapers reflecting on rain-slicked streets, holographic billboards displaying Japanese and English text, cinematic wide-angle shot from a low street-level angle looking upward, volumetric fog with dominant magenta and cyan palette accented by deep black shadows, moody and atmospheric, photorealistic with ultra-detailed wet surfaces, 16:9 aspect ratio.

### Example 3 — Already-detailed input (skip enhancement)
**Input**: "Studio ghibli style watercolor of a small bakery on a quiet european street at golden hour, warm cozy colors, viewed from across the cobblestone road, with a black cat sitting near the door"

**Action**: 30+ words, has style/composition/lighting/mood — pass to Codex as-is. (Or apply only minor cleanup if there's an obvious gap.)

### Example 4 — Mood piece
**Input**: "외로운 등대"

**Enhanced**:
> A solitary white lighthouse perched on a craggy headland during a storm, dark turbulent ocean waves crashing against black rocks below, oil painting style with visible impasto brushstrokes, wide establishing shot from sea level, dramatic chiaroscuro lighting from a single beam piercing thick grey clouds, muted palette of slate blue, charcoal grey, and isolated warm yellow from the lamp, melancholic and majestic mood, painterly texture, 3:2 aspect ratio.

## Anti-patterns

Avoid these — they make prompts worse:

- **Stacking 10+ adjectives**: pick the strongest, drop the rest
- **Contradicting cues**: "minimalist + intricate detail", "photorealistic + cartoon"
- **Vague modifiers**: "beautiful", "nice", "amazing" — these add no signal
- **Long lists of artists**: one stylistic reference is plenty
- **Negative prompts by default**: only add when there's a known failure mode
- **All-caps emphasis**: doesn't help and looks strange in the prompt log
