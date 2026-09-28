#!/usr/bin/env bash
# ʕ •ᴥ•ʔ✿ remove Horde statusline from ~/.cursor ✿ ʕ •ᴥ•ʔ
set -euo pipefail
dest="${CURSOR_HOME:-$HOME/.cursor}"

# Clear Kitty crest if possible
if command -v kitten >/dev/null && [[ -n "${KITTY_LISTEN_ON:-}" ]]; then
  kitten @ set-background-image none >/dev/null 2>&1 || true
fi

rm -f \
  "$dest/statusline.sh" \
  "$dest/kitty-image.sh" \
  "$dest/hooks/session-art.sh" \
  "$dest/assets/horde-agent.png" \
  "$dest/assets/horde-bg-corner.png" \
  "$dest/assets/.horde-placed"

# Drop legacy assets from older installs
rm -f \
  "$dest/assets/horde-status.icat" \
  "$dest/assets/horde.ansi" \
  "$dest/assets/horde-grid.png" \
  "$dest/assets/horde-agent-cut.png"

python3 - "$dest" <<'PY'
import json, sys
from pathlib import Path
dest = Path(sys.argv[1]).expanduser()
cfg = dest / "cli-config.json"
if cfg.exists():
    data = json.loads(cfg.read_text())
    sl = data.get("statusLine") or {}
    cmd = str(sl.get("command") or "")
    if "statusline.sh" in cmd:
        data.pop("statusLine", None)
        cfg.write_text(json.dumps(data, indent=2) + "\n")
        print(f"removed statusLine from {cfg}")

hooks = dest / "hooks.json"
if hooks.exists():
    try:
        data = json.loads(hooks.read_text())
    except json.JSONDecodeError:
        raise SystemExit(0)
    changed = False
    for event, entries in list((data.get("hooks") or {}).items()):
        keep = [e for e in entries if "session-art.sh" not in str(e.get("command", ""))]
        if len(keep) != len(entries):
            changed = True
            if keep:
                data["hooks"][event] = keep
            else:
                data["hooks"].pop(event, None)
    if changed:
        if data.get("hooks"):
            hooks.write_text(json.dumps(data, indent=2) + "\n")
            print(f"cleaned session-art hook in {hooks}")
        else:
            hooks.unlink(missing_ok=True)
            print(f"removed empty {hooks}")
PY

echo "uninstalled from $dest"
