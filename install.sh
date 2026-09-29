#!/usr/bin/env bash
# ʕ •ᴥ•ʔ✿ install Horde statusline into ~/.cursor ✿ ʕ •ᴥ•ʔ
set -euo pipefail
root=$(cd "$(dirname "$0")" && pwd)
dest="${CURSOR_HOME:-$HOME/.cursor}"

if [[ ! -f "$root/assets/horde-bg-corner.png" ]]; then
  if command -v python3 >/dev/null && python3 -c 'import PIL' 2>/dev/null; then
    "$root/scripts/build-corner-bg.sh"
  else
    echo "missing assets/horde-bg-corner.png — run scripts/build-corner-bg.sh first" >&2
    exit 1
  fi
fi

mkdir -p "$dest/assets" "$dest/assets/icons" "$dest/hooks"
install -m 0755 "$root/statusline.sh" "$dest/statusline.sh"
install -m 0755 "$root/kitty-image.sh" "$dest/kitty-image.sh"
install -m 0755 "$root/hooks/session-art.sh" "$dest/hooks/session-art.sh"
install -m 0644 "$root/hooks.json" "$dest/hooks.json"
install -m 0644 "$root/assets/horde-agent.png" "$dest/assets/horde-agent.png"
install -m 0644 "$root/assets/horde-bg-corner.png" "$dest/assets/horde-bg-corner.png"
if [[ -d "$root/assets/icons" ]]; then
  install -m 0644 "$root/assets/icons/"*.png "$dest/assets/icons/"
fi

python3 - "$dest" <<'PY'
import json, sys
from pathlib import Path
dest = Path(sys.argv[1]).expanduser()
cfg = dest / "cli-config.json"
if not cfg.exists():
    print(f"no {cfg} — add statusLine by hand (see README)")
    raise SystemExit(0)
data = json.loads(cfg.read_text())
data["statusLine"] = {
    "type": "command",
    "command": str(dest / "statusline.sh"),
    "padding": 1,
}
cfg.write_text(json.dumps(data, indent=2) + "\n")
print(f"statusLine → {dest / 'statusline.sh'}")
PY

if [[ -n "${KITTY_LISTEN_ON:-}" ]]; then
  "$dest/kitty-image.sh" || true
fi

echo "installed into $dest"
echo "open Cursor CLI in Kitty and send a message so the status refreshes"
