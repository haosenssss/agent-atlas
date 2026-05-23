#!/usr/bin/env bash
# Generate a cover image for a notes piece via Gemini CLI.
# Style is locked: 简约杂志风 + Anthropic-like warm earth palette.
# Default aspect ratio: 3:4 vertical (suitable for 小红书 / Xiaohongshu).
# Override via the optional 4th arg, e.g. "16:9", "1:1", "9:16", "2.35:1".
#
# Usage:
#   scripts/gen-cover.sh <issue> "<hook-zh>" "<visual_hint>" [aspect-ratio]
#
# Example:
#   scripts/gen-cover.sh 01 \
#     "先别急着搭 Agent" \
#     "two interlocking arcs forming a soft loop, with one solid terracotta dot and one charcoal ring sitting on it"
#
# Output: notes/covers/<issue>-cover.png

set -euo pipefail

if [[ $# -lt 3 ]]; then
  cat >&2 <<USAGE
Usage: $0 <issue> "<hook-zh>" "<visual_hint>" [aspect-ratio]
  issue          Two-digit issue number (e.g. 01); aligns with notes/NN-*.md
  hook-zh        ONE short Chinese punchline — the main text on the cover
  visual_hint    Short description of the abstract illustration metaphor
  aspect-ratio   Optional; default "3:4" (vertical for 小红书).
                 Supported: "3:4", "9:16", "16:9", "1:1", "2.35:1", or raw "WxH"
USAGE
  exit 2
fi

ISSUE="$1"
HOOK="$2"
VISUAL="$3"
RATIO="${4:-3:4}"

# Map ratio -> exact resolution
case "$RATIO" in
  "3:4")     RES="1080x1440" ;;
  "9:16")    RES="1080x1920" ;;
  "16:9")    RES="1920x1080" ;;
  "1:1")     RES="1080x1080" ;;
  "2.35:1")  RES="1920x817"  ;;
  *x*)       RES="$RATIO"    ;;
  *)
    echo "Unknown aspect ratio: $RATIO" >&2
    exit 2
    ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$REPO_ROOT/notes/covers"
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/${ISSUE}-cover.png"

PROMPT=$(cat <<EOF
Generate a single $RATIO ($RES) PNG cover image and save it to exactly this absolute path:
$OUT

UNIFIED STYLE (apply strictly for every cover; do not deviate):

Platform context
- This is a 小红书 (Xiaohongshu) social-feed cover. Composition is PORTRAIT / VERTICAL ($RATIO).
- Aesthetic: editorial magazine cover + Anthropic / Claude restrained warm style.
- Text is intentionally MINIMAL — see below.

Tool constraint (strict)
- Your ONLY task is to produce the PNG image at the absolute path specified above.
- Do NOT modify, create, or delete any other file in the workspace.
- Do NOT touch PROGRESS.md, CLAUDE.md, notes/, scripts/, or any file other than the target PNG.
- Do NOT run shell commands beyond what is strictly required to write that one PNG.

Text on the cover (only TWO text elements; absolutely no more)
- Small uppercase English label "THE AGENT LOOP · ISSUE $ISSUE", placed neatly near the top.
- One short Chinese hook line, set as the most prominent text element of the cover:
  "$HOOK"
- No subtitle, no English title, no body copy, no decorative text — nothing else.

Palette (strict)
- Background: warm cream paper, around #F0EEE6.
- Primary accent: warm Anthropic terracotta, around #CC785C.
- Text: deep charcoal, around #1F1F1F.
- Sparingly allowed muted earth tones (clay, sand, soft sage) for secondary illustration accents.
- Forbidden: neon, pure black, blue, cyan, purple, gradients, glow, drop shadow, 3D, photorealism.

Typography
- Chinese hook: large, refined humanist Chinese typeface (Songti/serif for warmth, or a refined modern sans like PingFang / Noto Sans CJK). Not heavy bold, not decorative, not script.
- English label: small uppercase Latin, generous letter-spacing, light or regular weight.
- All text crisply rendered — no shadow, no outline, no rotation, no warping.

Illustration
- A single large abstract geometric illustration occupies most of the canvas, balanced with the text zone.
- Soft curves and primitive shapes only: circles, arcs, lines, rectangles, small nodes.
- Two-color illustration: terracotta on cream, with optional thin charcoal lines if helpful.
- Expresses the theme ABSTRACTLY. No literal screens, faces, hands, robots, logos, or text inside the illustration.
- Lots of intentional negative space. Composition feels balanced and breathable for a vertical canvas.

Texture
- Very subtle paper grain. Restrained, print/editorial feel.

Per-piece variables for THIS cover
- Issue label (small uppercase, near top): THE AGENT LOOP · ISSUE $ISSUE
- Chinese hook (large, dominant text): $HOOK
- Abstract illustration metaphor for the main visual: $VISUAL

After writing the file, on the last line of your output write only the absolute path of the saved file (nothing else on that line).
EOF
)

cd "$REPO_ROOT"
echo "Generating cover -> $OUT  ($RATIO / $RES)"
echo "Hook:   $HOOK"
echo "Visual: $VISUAL"
echo "---"
gemini -y --skip-trust -p "$PROMPT"
echo "---"
ls -la "$OUT"
file "$OUT"
