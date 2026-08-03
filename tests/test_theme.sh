#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d /tmp/clavis-zsh-theme-test.XXXXXX)
cleanup() { rm -rf -- "$test_dir"; }
trap cleanup EXIT

home="$test_dir/home"
state="$test_dir/state"
cache="$test_dir/cache"
zshrc="$home/.zshrc"
mkdir -p "$home"
printf '# user setting\nexport CLAVIS_ZSH_TEST=1\n' > "$zshrc"

export HOME="$home"
export XDG_STATE_HOME="$state"
export XDG_CACHE_HOME="$cache"
export CLAVIS_ZSHRC="$zshrc"
export CLAVIS_ZSH_THEME_COLOR_FILE="$cache/clavis/zsh-prompt-colors.zsh"
export CLAVIS_ZSH_THEME_MATUGEN_COLOR='#6750a4'
export PATH="$repo_dir/.build:$PATH"

bash "$repo_dir/src/apply.sh" --share-dir "$repo_dir/src"
bash "$repo_dir/src/apply.sh" --share-dir "$repo_dir/src"

[[ $(grep -c '^# BEGIN CLAVIS ZSH THEME$' "$zshrc") -eq 1 ]]
[[ -s "$CLAVIS_ZSH_THEME_COLOR_FILE" ]]
[[ -d "$state/clavis/backups" ]]
grep -q 'export CLAVIS_ZSH_TEST=1' "$zshrc"
zsh -dfc "source '$zshrc'; [[ -n \"\$PROMPT\" ]]"

printf '# user change after apply\n' >> "$zshrc"
bash "$repo_dir/src/apply.sh" --share-dir "$repo_dir/src" --uninstall
! grep -q '^# BEGIN CLAVIS ZSH THEME$' "$zshrc"
grep -q 'user change after apply' "$zshrc"
printf 'Zsh theme tests passed\n'
