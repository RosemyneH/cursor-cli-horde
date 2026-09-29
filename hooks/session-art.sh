#!/usr/bin/env bash
# ʕ •ᴥ•ʔ✿ place crest + keep BR anchor fresh across resizes ✿ ʕ •ᴥ•ʔ
"$HOME/.cursor/kitty-image.sh" >/dev/null 2>&1 || true

# resize watcher — statusline only ticks on chat activity
lock="$HOME/.cursor/assets/.horde-watch.lock"
mkdir -p "$HOME/.cursor/assets"
if command -v flock >/dev/null; then
  flock -n "$lock" -c '
    while [[ -n "${KITTY_LISTEN_ON:-}" ]]; do
      "$HOME/.cursor/kitty-image.sh" >/dev/null 2>&1 || true
      sleep 0.5
    done
  ' >/dev/null 2>&1 &
fi

echo '{}'
