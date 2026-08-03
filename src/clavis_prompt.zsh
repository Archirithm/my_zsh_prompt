# shellcheck shell=zsh

typeset -g CLAVIS_ZSH_THEME_SHARE=${CLAVIS_ZSH_THEME_SHARE:-${${(%):-%x}:A:h}}
typeset -g CLAVIS_ZSH_THEME_COLOR_FILE=${CLAVIS_ZSH_THEME_COLOR_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/clavis/zsh-prompt-colors.zsh}

if [[ -r "$CLAVIS_ZSH_THEME_COLOR_FILE" ]]; then
    source "$CLAVIS_ZSH_THEME_COLOR_FILE"
fi

autoload -Uz add-zsh-hook
typeset -g CLAVIS_PROMPT_START_SECONDS=$SECONDS

clavis_prompt_preexec() {
    CLAVIS_PROMPT_START_SECONDS=$SECONDS
}

clavis_prompt_precmd() {
    local exit_code=$?
    local elapsed=$(( (SECONDS - CLAVIS_PROMPT_START_SECONDS) * 1000 ))
    local duration="${elapsed}ms"
    local columns=${COLUMNS:-80}
    if (( elapsed == 0 )); then
        duration=""
    fi
    if (( $+commands[prompt] )); then
        PROMPT="$(command prompt "$exit_code" "$duration" "$columns")"
    elif [[ -x "$CLAVIS_ZSH_THEME_SHARE/prompt" ]]; then
        PROMPT="$("$CLAVIS_ZSH_THEME_SHARE/prompt" "$exit_code" "$duration" "$columns")"
    else
        PROMPT='%~ %# '
    fi
}

add-zsh-hook -d preexec clavis_prompt_preexec 2>/dev/null || true
add-zsh-hook -d precmd clavis_prompt_precmd 2>/dev/null || true
add-zsh-hook preexec clavis_prompt_preexec
add-zsh-hook precmd clavis_prompt_precmd
clavis_prompt_precmd
