#!/usr/bin/env bash
# ʕ •ᴥ•ʔ✿ bake crest into bottom-right of a transparent kitty background ✿ ʕ •ᴥ•ʔ
# Prefer kitty-image.sh at runtime (measures the live window). This is for offline rebuilds.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
src=${1:-"$root/assets/horde-agent.png"}
out=${2:-"$root/assets/horde-bg-corner.png"}
W=${3:-1125}
H=${4:-1340}
tall=${5:-96}

python3 - "$src" "$out" "$W" "$H" "$tall" <<'PY'
import sys
from PIL import Image
src, out, W, H, tall = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
crest = Image.open(src).convert("RGBA")
canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ratio = tall / crest.height
crest = crest.resize((max(1, int(crest.width * ratio)), tall), Image.NEAREST)
pad_x, pad_y = 18, 14
x = max(0, W - crest.width - pad_x)
y = max(0, H - crest.height - pad_y)
canvas.paste(crest, (x, y), crest)
canvas.save(out)
print(f"wrote {out} crest={crest.size} at ({x},{y}) on {W}x{H}")
PY
