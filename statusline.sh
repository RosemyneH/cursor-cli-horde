#!/usr/bin/env bash
# ʕ •ᴥ•ʔ✿ horde agent ✿ ʕ •ᴥ•ʔ
payload=$(cat)

C=$'\033[38;2;0;247;255m'
C2=$'\033[38;2;0;217;255m'
P=$'\033[38;2;255;146;165m'
M=$'\033[38;2;255;0;128m'
Y=$'\033[38;2;255;217;0m'
B=$'\033[38;2;130;159;255m'
D=$'\033[38;2;90;90;120m'
H=$'\033[38;2;232;56;48m'
HG=$'\033[38;2;232;186;64m'
R=$'\033[0m'

# ʕ ◕ᴥ◕ ʔ✿ resize-safe crest: rebuild canvas when window W×H changes ✿ ʕ ◕ᴥ◕ ʔ
if [[ -n "${KITTY_LISTEN_ON:-}" ]]; then
  "$HOME/.cursor/kitty-image.sh" >/dev/null 2>&1 &
fi

model=$(printf '%s' "$payload" | jq -r '.model.display_name // "agent"')
params=$(printf '%s' "$payload" | jq -r '.model.param_summary // empty')
pct=$(printf '%s' "$payload" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
dir=$(printf '%s' "$payload" | jq -r '.workspace.current_dir // .cwd // empty')
vim=$(printf '%s' "$payload" | jq -r '.vim.mode // empty')
worktree=$(printf '%s' "$payload" | jq -r '.worktree.name // empty')
session=$(printf '%s' "$payload" | jq -r '.session_name // empty')
autorun=$(printf '%s' "$payload" | jq -r '.autorun // false')

[[ "$pct" =~ ^[0-9]+$ ]] || pct=0
(( pct > 100 )) && pct=100

# ʕ •ᴥ•ʔ✿ horde bar: bright red on iron track ✿ ʕ •ᴥ•ʔ
TRACK=$'\033[48;2;36;14;14m'
EMPTY=$'\033[38;2;92;48;42m'
bar_w=14
filled=$((pct * bar_w / 100))
fill=""
for ((i = 0; i < bar_w; i++)); do
  if (( i < filled )); then
    fill+="${H}█"
  else
    fill+="${EMPTY}░"
  fi
done
bar="${HG}[${TRACK}${fill}${R}${HG}]${R}"

if (( pct >= 85 )); then
  pct_c=$'\033[38;2;255;236;196m'
elif (( pct >= 60 )); then
  pct_c="$HG"
else
  pct_c=$'\033[38;2;255;96;80m'
fi

branch=""
if [[ -n "$dir" ]] && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
fi

label="${dir##*/}"
[[ -n "$worktree" ]] && label="$worktree"

bits=()
[[ -n "$label" ]] && bits+=("${C}${label}${R}")
[[ -n "$branch" ]] && bits+=("${Y}${branch}${R}")
[[ -n "$vim" ]] && bits+=("${M}${vim}${R}")
[[ -n "$session" ]] && bits+=("${D}${session}${R}")
meta=""
if ((${#bits[@]})); then
  meta="${bits[0]}"
  for ((i = 1; i < ${#bits[@]}; i++)); do
    meta+=" ${C2}·${R} ${bits[$i]}"
  done
fi

# ʕノ•ᴥ•ʔノ✿ red mark + model / rage bar — crest is the kitty overlay ✿ ʕノ•ᴥ•ʔノ
printf '%s⚔%s %s%s' "$H" "$R" "$P" "$model"
[[ -n "$params" ]] && printf ' %s%s' "$B" "$params"
printf '%s  %s %s%d%%%s' "$R" "$bar" "$pct_c" "$pct" "$R"
[[ "$autorun" == "true" ]] && printf ' %srun%s' "$Y" "$R"
printf '\n'
printf '%s\n' "$meta"
