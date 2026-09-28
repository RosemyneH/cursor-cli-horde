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

Crest is baked into `assets/horde-bg-corner.png` (transparent canvas, mark in the **bottom-right**). Rebuild after changing size or window geometry:

```bash
# tall=crest height in px; W H ≈ kitty window pixels
./scripts/build-corner-bg.sh assets/horde-agent.png assets/horde-bg-corner.png 1125 1340 96
./install.sh
```

Or paint without reinstall:

```bash
~/.cursor/kitty-image.sh
kitten @ set-background-image none   # hide crest
```

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

Cursor’s TUI redraw wipes `kitten icat --place`. This project uses Kitty remote control instead:

```bash
kitten @ set-background-image --layout=clamped ~/.cursor/assets/horde-bg-corner.png
```

That survives redraws. Status stdout stays text-only (⚔, rage bar, path/branch).

## Layout

```
statusline.sh              status text (model, rage bar, meta)
kitty-image.sh             set-background-image helper
hooks/session-art.sh       sessionStart → place crest
assets/horde-agent.png     source crest (transparent)
assets/horde-bg-corner.png canvas with crest bottom-right
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
