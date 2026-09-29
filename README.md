# Cursor CLI Horde

WoW Horde–themed **Cursor CLI** status line: blood-red context bar, gold trim, and a crest in the bottom-right under the chat box (Kitty graphics).

Requires [Kitty](https://sw.kovidgoyal.net/kitty/) + [Cursor CLI](https://cursor.com/docs/cli) + `jq`. Crest rebuild needs Python + Pillow.

## Quick setup

```bash
git clone https://github.com/RosemyneH/cursor-cli-horde.git
cd cursor-cli-horde
./install.sh
```

Then open Cursor CLI **inside Kitty** and send a message so the status refreshes. The crest should appear bottom-right under the input box.

## Remove

```bash
cd cursor-cli-horde
./uninstall.sh
```

This removes the scripts/assets under `~/.cursor`, clears `statusLine` when it pointed at this statusline, strips the `session-art` hook, and clears the Kitty background image when possible.

## Settings

### Status line (`~/.cursor/cli-config.json`)

`install.sh` writes:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.cursor/statusline.sh",
    "padding": 1
  }
}
```

| Field | Default | Notes |
|---|---|---|
| `padding` | `1` | Horizontal inset for the status container |
| `updateIntervalMs` | `300` | Min refresh interval (CLI clamps ≥ 300) |
| `timeoutMs` | `2000` | Kill the status command if slower |

Example with slower refresh:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.cursor/statusline.sh",
    "padding": 1,
    "updateIntervalMs": 1000
  }
}
```

Override install path with `CURSOR_HOME` (default `~/.cursor`):

```bash
CURSOR_HOME=~/.cursor-dev ./install.sh
CURSOR_HOME=~/.cursor-dev ./uninstall.sh
```

### Crest size / position

The crest is anchored to Kitty’s **bottom-right cell** (`cols - width`, `rows - height`).
On each paint, `kitty-image.sh` reads the live grid + pane pixels, maps that cell
block to a 1:1 background canvas, and applies it — so splits, stacks, and resizes
keep the crest in the under-chat gutter.

| Env | Default | Meaning |
|---|---|---|
| `HORDE_ICON` | `crest` | Icon name, or `cycle` / `random` |
| `HORDE_ICONS_DIR` | `~/.cursor/assets/icons` | Icon pack directory |
| `HORDE_CREST_COLS` | `7` | Crest width in cells |
| `HORDE_CREST_ROWS` | `5` | Crest height in cells |
| `HORDE_PAD_RIGHT` | `1` | Cells inset from the right edge |
| `HORDE_PAD_BOTTOM` | `0` | Cells inset from the bottom edge |

```bash
HORDE_ICON=skull ~/.cursor/kitty-image.sh
HORDE_ICON=cycle ~/.cursor/kitty-image.sh   # rotate through the pack
HORDE_ICON=axe-wow ~/.cursor/kitty-image.sh
kitten @ set-background-image none          # hide
```

Pack includes: `crest`, `axe`, `skull`, `wolf`, `fist`, `hammer`, `potion`, `shield`,
plus painted `axe-wow` / `skull-wow`.

A session-start watcher re-applies every ~0.5s so pure resizes (no chat activity)
still re-anchor.

### Session hook (`~/.cursor/hooks.json`)

Places the crest once at session start:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "command": "./hooks/session-art.sh",
        "timeout": 5
      }
    ]
  }
}
```

## How the crest works

Cursor’s TUI redraw wipes `kitten icat --place`. A fixed-pixel background also
fails: after resize or a split layout the crest is no longer in the visible
bottom-right gutter.

So we **draw from the bottom-right of the live cell grid**:

1. Read `columns` / `lines` from `kitten @ ls`
2. Take a `CREST_COLS × CREST_ROWS` block at `(cols - w - pad, rows - h - pad)`
3. Map that block to pane pixels (Sway rect ÷ cells)
4. Bake a transparent 1:1 canvas with the crest only in that rect
5. `kitten @ set-background-image --layout=clamped` (survives TUI redraw)
6. Session watcher + statusline re-run so resizes re-anchor

Status stdout stays text-only (⚔, rage bar, path/branch).

## Layout

```
statusline.sh              status text (model, rage bar, meta)
kitty-image.sh             set-background-image helper
hooks/session-art.sh       sessionStart → place crest
assets/horde-agent.png     legacy crest path (still installed)
assets/icons/*.png         WoW icon pack (crest, axe, skull, …)
assets/horde-bg-corner.png runtime canvas (bottom-right)
scripts/build-corner-bg.sh rebuild the canvas
install.sh / uninstall.sh  setup / removal
```

## Manual test (no Kitty)

```bash
echo '{"model":{"display_name":"Auto"},"context_window":{"used_percentage":34},"workspace":{"current_dir":"'"$PWD"'"}}' \
  | ./statusline.sh
```

## License

Personal / fun use. Horde imagery © Blizzard — not affiliated.
