#!/usr/bin/env bash
# ʕ •ᴥ•ʔ✿ crest pinned to Kitty's bottom-right cell corner ✿ ʕ •ᴥ•ʔ
# Origin is always (cols, rows): works across splits, stacks, and resizes.
# Background image survives Cursor TUI redraws; canvas is 1:1 with the pane.
#
# Icon pack: HORDE_ICON=crest|axe|skull|wolf|fist|hammer|potion|shield|axe-wow|skull-wow
#            HORDE_ICON=cycle   rotate on each paint
#            HORDE_ICON=random  pick at random each paint
set -u

icons_dir=${HORDE_ICONS_DIR:-$HOME/.cursor/assets/icons}
icon_name=${HORDE_ICON:-crest}
out=${2:-$HOME/.cursor/assets/horde-bg-corner.png}
meta=${HORDE_BG_META:-$HOME/.cursor/assets/.horde-bg-size}

resolve_icon() {
  local name=$1
  local list=()
  local f
  if [[ -d "$icons_dir" ]]; then
    for f in "$icons_dir"/*.png; do
      [[ -f "$f" ]] && list+=("$f")
    done
  fi
  if ((${#list[@]} == 0)); then
    printf '%s\n' "${1:-$HOME/.cursor/assets/horde-agent.png}"
    return
  fi
  case "$name" in
    cycle)
      local i=0
      if [[ -f "$HOME/.cursor/assets/.horde-icon-i" ]]; then
        i=$(cat "$HOME/.cursor/assets/.horde-icon-i" 2>/dev/null || echo 0)
      fi
      [[ "$i" =~ ^[0-9]+$ ]] || i=0
      local pick=${list[$((i % ${#list[@]}))]}
      printf '%s' $((i + 1)) > "$HOME/.cursor/assets/.horde-icon-i"
      printf '%s\n' "$pick"
      ;;
    random)
      printf '%s\n' "${list[RANDOM % ${#list[@]}]}"
      ;;
    *)
      if [[ -f "$icons_dir/$name.png" ]]; then
        printf '%s\n' "$icons_dir/$name.png"
      elif [[ -f "$name" ]]; then
        printf '%s\n' "$name"
      elif [[ -f "$HOME/.cursor/assets/horde-agent.png" ]]; then
        printf '%s\n' "$HOME/.cursor/assets/horde-agent.png"
      else
        printf '%s\n' "${list[0]}"
      fi
      ;;
  esac
}

# arg1 may be a path or an icon name; HORDE_ICON wins when arg omitted
if [[ $# -ge 1 && -n "${1:-}" ]]; then
  if [[ -f "$1" ]]; then
    src=$1
  else
    src=$(resolve_icon "$1")
  fi
else
  src=$(resolve_icon "$icon_name")
fi

# size in cells (drawn from the bottom-right origin)
wid=${HORDE_CREST_COLS:-7}
hid=${HORDE_CREST_ROWS:-5}
right_pad=${HORDE_PAD_RIGHT:-1}
bottom_pad=${HORDE_PAD_BOTTOM:-0}

[[ -f "$src" ]] || exit 0
command -v kitten >/dev/null || exit 0
command -v python3 >/dev/null || exit 0
command -v jq >/dev/null || exit 0

to=${KITTY_LISTEN_ON:-}
if [[ -z "$to" ]]; then
  for s in "$HOME"/.cache/kitty/ctrl-*; do
    [[ -S "$s" ]] || continue
    to="unix:$s"
    break
  done
fi
[[ -n "$to" ]] || exit 0

export KITTY_LISTEN_ON="$to"
export HORDE_CREST_COLS="$wid" HORDE_CREST_ROWS="$hid"
export HORDE_PAD_RIGHT="$right_pad" HORDE_PAD_BOTTOM="$bottom_pad"
export KITTY_PID="${KITTY_PID:-}"
# bust cache when icon changes
export HORDE_SRC_KEY="$src"

KITTY_RC="$to" python3 - "$src" "$out" "$meta" <<'PY' || exit 0
import json, os, subprocess, sys
from pathlib import Path

src, out, meta_path = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
wid = int(os.environ.get("HORDE_CREST_COLS", "7"))
hid = int(os.environ.get("HORDE_CREST_ROWS", "5"))
right_pad = int(os.environ.get("HORDE_PAD_RIGHT", "1"))
bottom_pad = int(os.environ.get("HORDE_PAD_BOTTOM", "0"))
pid = int(os.environ.get("KITTY_PID") or "0")
rc = os.environ.get("KITTY_RC") or os.environ.get("KITTY_LISTEN_ON") or ""

def kitten_ls():
    cmd = ["kitten", "@"]
    if rc:
        cmd += ["--to", rc]
    cmd.append("ls")
    return json.loads(subprocess.check_output(cmd, text=True))

def grid():
    data = kitten_ls()
    for os_win in data:
        for tab in os_win.get("tabs", []):
            for win in tab.get("windows", []):
                if win.get("is_self") or win.get("is_active"):
                    return int(win["columns"]), int(win["lines"])
    win = data[0]["tabs"][0]["windows"][0]
    return int(win["columns"]), int(win["lines"])

def sway_pixels(want_pid: int):
    try:
        tree = json.loads(subprocess.check_output(["swaymsg", "-t", "get_tree"], text=True))
    except (FileNotFoundError, subprocess.CalledProcessError, json.JSONDecodeError):
        return None
    hit = None

    def walk(n):
        nonlocal hit
        if hit is not None:
            return
        if (n.get("app_id") or "") == "kitty":
            r = n.get("rect") or {}
            w, h = int(r.get("width") or 0), int(r.get("height") or 0)
            if w >= 32 and h >= 32 and (not want_pid or n.get("pid") == want_pid):
                hit = (w, h)
                return
        for c in n.get("nodes", []) + n.get("floating_nodes", []):
            walk(c)

    walk(tree)
    return hit

cols, rows = grid()
# shrink crest for tiny panes — still anchored to BR
wid = max(2, min(wid, cols - 2))
hid = max(2, min(hid, rows - 2))

px = sway_pixels(pid)
if px:
    W, H = px
else:
    # fallback: assume square-ish cells
    W, H = max(320, cols * 10), max(240, rows * 20)

cell_w = W / cols
cell_h = H / rows

# ʕ ● ᴥ ●ʔ✿ pixel rect of the bottom-right cell block ✿ ʕ ● ᴥ ●ʔ
left_cell = max(0, cols - wid - right_pad)
top_cell = max(0, rows - hid - bottom_pad)
x = int(round(left_cell * cell_w))
y = int(round(top_cell * cell_h))
cw = max(1, int(round(wid * cell_w)))
ch = max(1, int(round(hid * cell_h)))
# clamp inside pane
x = min(max(0, x), max(0, W - cw))
y = min(max(0, y), max(0, H - ch))

key = f"{cols}x{rows} {W}x{H} {wid}x{hid}@{left_cell}x{top_cell} p={right_pad},{bottom_pad} src={src}"
prev = meta_path.read_text().strip() if meta_path.exists() else ""
if key != prev or not out.exists():
    from PIL import Image

    crest = Image.open(src).convert("RGBA")
    crest = crest.resize((cw, ch), Image.NEAREST)
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    canvas.paste(crest, (x, y), crest)
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)
    meta_path.write_text(key + "\n")
    print(f"rebuilt BR {wid}x{hid} cells -> px ({x},{y},{cw},{ch}) on {cols}x{rows}", file=sys.stderr)

print(key)
PY

kitten @ --to "$to" set-background-image --layout=clamped "$out" >/dev/null 2>&1 || true
