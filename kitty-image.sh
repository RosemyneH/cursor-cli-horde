#!/usr/bin/env bash
# ʕ •ᴥ•ʔ✿ Horde crest via kitty background (bottom-right, under chat box) ✿ ʕ •ᴥ•ʔ
# icat --place gets wiped every Cursor TUI paint; set-background-image does not.
set -u

img=${1:-$HOME/.cursor/assets/horde-bg-corner.png}

[[ -f "$img" ]] || exit 0
command -v kitten >/dev/null || exit 0

# ʕ ● ᴥ ●ʔ✿ only paint via known kitty sockets ✿ ʕ ● ᴥ ●ʔ
targets=()
if [[ -n "${KITTY_LISTEN_ON:-}" ]]; then
  targets+=("$KITTY_LISTEN_ON")
else
  for s in "$HOME"/.cache/kitty/ctrl-*; do
    [[ -S "$s" ]] && targets+=("unix:$s")
  done
fi
((${#targets[@]})) || exit 0

for to in "${targets[@]}"; do
  kitten @ --to "$to" set-background-image --layout=clamped "$img" >/dev/null 2>&1 || true
done
