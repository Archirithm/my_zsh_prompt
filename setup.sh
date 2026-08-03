#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
prefix=${CMAKE_INSTALL_PREFIX:-/usr/local}
share_dir=${CLAVIS_ZSH_THEME_SHARE_DIR:-$prefix/share/clavis-zsh-theme}
bin_dir=${CLAVIS_ZSH_THEME_BIN_DIR:-$prefix/bin}

usage() {
    cat <<'EOF'
clavis-zsh-theme source helper

Usage:
  ./setup.sh doctor
  ./setup.sh configure
  ./setup.sh build
  ./setup.sh test
  ./setup.sh install
  ./setup.sh apply
  ./setup.sh uninstall

Set CMAKE_INSTALL_PREFIX or CLAVIS_ZSH_THEME_SHARE_DIR for a test prefix.
EOF
}

command_name=${1:-help}
case "$command_name" in
    help|-h|--help) usage; exit 0 ;;
    doctor)
        command -v zsh >/dev/null 2>&1 && printf '[OK]   zsh\n' || { printf '[FAIL] zsh\n'; exit 1; }
        command -v git >/dev/null 2>&1 && printf '[OK]   git\n' || { printf '[FAIL] git\n'; exit 1; }
        ;;
    configure|build)
        printf 'No native build is required; shell sources are validated by test.\n'
        ;;
    test)
        exec bash "$repo_dir/tests/test_theme.sh"
        ;;
    install)
        install -d "$share_dir" "$bin_dir"
        install -m 0644 "$repo_dir/src/clavis_prompt.zsh" "$share_dir/clavis_prompt.zsh"
        install -m 0644 "$repo_dir/src/matugen-colors.zsh.in" "$share_dir/matugen-colors.zsh.in"
        install -m 0755 "$repo_dir/src/clavis-zsh-theme.sh" "$share_dir/clavis-zsh-theme.sh"
        install -m 0755 "$repo_dir/src/clavis-zsh-theme" "$bin_dir/clavis-zsh-theme"
        ;;
    apply)
        exec bash "$repo_dir/src/apply.sh" --share-dir "$share_dir"
        ;;
    uninstall)
        exec bash "$repo_dir/src/apply.sh" --share-dir "$share_dir" --uninstall
        ;;
    *) printf 'unknown command: %s\n' "$command_name" >&2; usage >&2; exit 2 ;;
esac

