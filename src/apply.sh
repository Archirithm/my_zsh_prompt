#!/usr/bin/env bash
set -euo pipefail

share_dir=""
uninstall=false
zshrc=${CLAVIS_ZSHRC:-${ZDOTDIR:-${HOME:?}}/.zshrc}
color_file=${CLAVIS_ZSH_THEME_COLOR_FILE:-${XDG_CACHE_HOME:-${HOME:?}/.cache}/clavis/zsh-prompt-colors.zsh}
matugen_source=${CLAVIS_ZSH_THEME_MATUGEN_SOURCE:-}
matugen_color=${CLAVIS_ZSH_THEME_MATUGEN_COLOR:-#6750a4}

usage() {
    printf 'Usage: %s --share-dir PATH [--zshrc PATH] [--color-file PATH] [--source-image PATH] [--color HEX] [--uninstall]\n' "$0" >&2
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --share-dir) [[ $# -ge 2 ]] || { usage; exit 2; }; share_dir=$2; shift 2 ;;
        --zshrc) [[ $# -ge 2 ]] || { usage; exit 2; }; zshrc=$2; shift 2 ;;
        --color-file) [[ $# -ge 2 ]] || { usage; exit 2; }; color_file=$2; shift 2 ;;
        --source-image) [[ $# -ge 2 ]] || { usage; exit 2; }; matugen_source=$2; shift 2 ;;
        --color) [[ $# -ge 2 ]] || { usage; exit 2; }; matugen_color=$2; shift 2 ;;
        --uninstall) uninstall=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage; exit 2 ;;
    esac
done

[[ -n "$share_dir" && -f "$share_dir/clavis-zsh-theme.sh" ]] || {
    printf 'Clavis Zsh theme share directory is incomplete: %s\n' "$share_dir" >&2
    exit 1
}

state_home=${CLAVIS_STATE_HOME:-${XDG_STATE_HOME:-${HOME:?}/.local/state}/clavis}
manifest="$state_home/zsh-theme.json"
begin='# BEGIN CLAVIS ZSH THEME'
end='# END CLAVIS ZSH THEME'

block() {
    printf '%s\n' "$begin"
    printf 'source %q\n' "$share_dir/clavis-zsh-theme.sh"
    printf '%s\n' "$end"
}

strip_block() {
    awk -v begin="$begin" -v end="$end" '
        $0 == begin { inside=1; next }
        $0 == end { inside=0; next }
        !inside { print }
    ' "$1"
}

backup_file() {
    [[ -f "$zshrc" ]] || return 0
    local timestamp backup_dir backup
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    backup_dir="$state_home/backups/$timestamp"
    backup="$backup_dir/zshrc"
    mkdir -p "$backup_dir"
    cp -p -- "$zshrc" "$backup"
    printf '%s\n' "$backup"
}

if [[ "$uninstall" == true ]]; then
    [[ -f "$zshrc" ]] || { rm -f -- "$manifest"; exit 0; }
    if [[ ! -f "$manifest" ]]; then
        printf 'No Clavis Zsh managed block manifest found; nothing removed.\n'
        exit 0
    fi
    expected_hash=$(sed -n 's/^blockSha256=//p' "$manifest" | head -n1)
    current_block=$(mktemp)
    trap 'rm -f -- "$current_block"' EXIT
    awk -v begin="$begin" -v end="$end" '
        $0 == begin { inside=1; print; next }
        inside { print }
        $0 == end { inside=0 }
    ' "$zshrc" > "$current_block"
    if [[ -n "$expected_hash" && -s "$current_block" ]] && command -v sha256sum >/dev/null 2>&1 \
        && [[ "$(sha256sum "$current_block" | awk '{print $1}')" != "$expected_hash" ]]; then
        printf 'Managed block was modified after apply; left it in place.\n' >&2
        exit 1
    fi
    temporary=$(mktemp "${zshrc}.XXXXXX")
    strip_block "$zshrc" > "$temporary"
    chmod --reference="$zshrc" "$temporary" 2>/dev/null || true
    mv -- "$temporary" "$zshrc"
    rm -f -- "$manifest"
    printf 'Removed the Clavis Zsh managed block from %s\n' "$zshrc"
    exit 0
fi

mkdir -p "$(dirname -- "$zshrc")" "$(dirname -- "$color_file")" "$state_home"
if [[ ! -f "$zshrc" ]]; then
    : > "$zshrc"
fi

backup=$(backup_file || true)
zshrc_temp=""
color_temp=$(mktemp "${color_file}.XXXXXX")
cleanup() { rm -f -- "$color_temp" "$zshrc_temp" "$config_temp" "$block_temp" 2>/dev/null || true; }
config_temp=""
block_temp=""
trap cleanup EXIT

if command -v matugen >/dev/null 2>&1; then
    config_temp=$(mktemp)
    {
        printf '[config]\nversion_check = false\n\n[templates.clavis_zsh]\n'
        printf 'input_path = "%s"\n' "$share_dir/matugen-colors.zsh.in"
        printf 'output_path = "%s"\n' "$color_temp"
    } > "$config_temp"
    if [[ -n "$matugen_source" ]]; then
        matugen --source-color-index 0 image "$matugen_source" --mode dark --type scheme-tonal-spot --config "$config_temp" >/dev/null
    else
        matugen color hex "$matugen_color" --mode dark --type scheme-tonal-spot --config "$config_temp" >/dev/null
    fi
else
    cat > "$color_temp" <<'EOF'
# Generated fallback palette; replace by running the Matugen hook.
typeset -g CLAVIS_PROMPT_PATH_BG='#2b2930'
typeset -g CLAVIS_PROMPT_PATH_FG='#e8e0e9'
typeset -g CLAVIS_PROMPT_GIT_BG='#4a4458'
typeset -g CLAVIS_PROMPT_GIT_FG='#e8def8'
typeset -g CLAVIS_PROMPT_LANG_BG='#633b48'
typeset -g CLAVIS_PROMPT_LANG_FG='#ffd8e4'
typeset -g CLAVIS_PROMPT_TIME_BG='#d0bcff'
typeset -g CLAVIS_PROMPT_TIME_FG='#381e72'
typeset -g CLAVIS_PROMPT_ERROR_BG='#93000a'
typeset -g CLAVIS_PROMPT_ERROR_FG='#ffdad6'
typeset -g CLAVIS_PROMPT_CONNECTOR='#938f99'
typeset -g CLAVIS_PROMPT_ARROW='#d0bcff'
EOF
fi
mv -- "$color_temp" "$color_file"

zshrc_temp=$(mktemp "${zshrc}.XXXXXX")
strip_block "$zshrc" > "$zshrc_temp"
block >> "$zshrc_temp"
chmod --reference="$zshrc" "$zshrc_temp" 2>/dev/null || true
mv -- "$zshrc_temp" "$zshrc"

block_temp=$(mktemp)
block > "$block_temp"
block_hash=$(sha256sum "$block_temp" | awk '{print $1}')
{
    printf 'zshrc=%s\n' "$zshrc"
    printf 'blockSha256=%s\n' "$block_hash"
    printf 'colorFile=%s\n' "$color_file"
    printf 'backup=%s\n' "$backup"
} > "$manifest"
printf 'Applied Clavis Zsh theme to %s\n' "$zshrc"
