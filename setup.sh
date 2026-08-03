#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir=${CLAVIS_ZSH_THEME_BUILD_DIR:-"$repo_dir/.build"}

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

Environment:
  CMAKE_INSTALL_PREFIX (default /usr/local)
  DESTDIR             (honoured by cmake --install)
EOF
}

command_name=${1:-help}
shift || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --build-dir)
            [[ $# -ge 2 ]] || { printf 'missing --build-dir value\n' >&2; exit 2; }
            build_dir=$2
            shift 2
            ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done
[[ "$build_dir" = /* ]] || build_dir="$repo_dir/$build_dir"

prefix_arg=()
if [[ -n "${CMAKE_INSTALL_PREFIX:-}" ]]; then
    prefix_arg=(-DCMAKE_INSTALL_PREFIX="$CMAKE_INSTALL_PREFIX")
fi

configure() {
    cmake -S "$repo_dir" -B "$build_dir" -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=OFF "${prefix_arg[@]}"
}

build() { configure; cmake --build "$build_dir" --parallel; }

test_cmd() {
    cmake -S "$repo_dir" -B "$build_dir" -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DBUILD_TESTING=ON "${prefix_arg[@]}"
    cmake --build "$build_dir" --parallel
    ctest --test-dir "$build_dir" --output-on-failure
}

effective_share_dir() {
    local prefix=${CMAKE_INSTALL_PREFIX:-/usr/local}
    local share="$prefix/share/clavis-zsh-theme"
    if [[ -n "${CLAVIS_ZSH_THEME_SHARE_DIR:-}" ]]; then
        share=$CLAVIS_ZSH_THEME_SHARE_DIR
    elif [[ -n "${DESTDIR:-}" ]]; then
        share="$DESTDIR$share"
    fi
    printf '%s\n' "$share"
}

case "$command_name" in
    help|-h|--help) usage; exit 0 ;;
    doctor)
        failed=0
        for command in cmake c++ git zsh; do
            command -v "$command" >/dev/null 2>&1 \
                && printf '[OK]   %s\n' "$command" \
                || { printf '[FAIL] %s\n' "$command"; failed=1; }
        done
        command -v matugen >/dev/null 2>&1 \
            && printf '[OK]   matugen (optional palette renderer)\n' \
            || printf '[WARN] matugen (optional; apply uses a generated fallback palette)\n'
        exit "$failed"
        ;;
    configure) configure ;;
    build) build ;;
    test) test_cmd ;;
    install) build; cmake --install "$build_dir" ;;
    apply)
        exec bash "$repo_dir/src/apply.sh" --share-dir "$(effective_share_dir)"
        ;;
    uninstall)
        bash "$repo_dir/src/apply.sh" --share-dir "$(effective_share_dir)" --uninstall
        manifest="$build_dir/install_manifest.txt"
        [[ -f "$manifest" ]] || exit 0
        destdir=${DESTDIR:-}
        while IFS= read -r path; do
            [[ -n "$path" ]] || continue
            target="$path"
            [[ -n "$destdir" ]] && target="$destdir$path"
            [[ -e "$target" || -L "$target" ]] && rm -f -- "$target"
        done < "$manifest"
        ;;
    *) printf 'unknown command: %s\n' "$command_name" >&2; usage >&2; exit 2 ;;
esac
