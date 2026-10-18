#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    printf 'Usage: bash install-tex.sh [installation-directory] [shell-rc]\nDefault: ~/.local/share/tex-cli and ${ZDOTDIR:-$HOME}/.zshrc\n'
    exit 0
fi
if (( $# > 2 )); then
    printf 'Usage: bash install-tex.sh [installation-directory] [shell-rc]\n' >&2
    exit 2
fi

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
install_dir=${1:-${HOME}/.local/share/tex-cli}
shell_rc=${2:-${ZDOTDIR:-$HOME}/.zshrc}
mkdir -p -- "$install_dir" "$(dirname -- "$shell_rc")"
install_dir=$(cd -- "$install_dir" && pwd -P)
if [[ "$source_dir" != "$install_dir" ]]; then
    cp -- "$source_dir/tex.sh" "$install_dir/tex.sh"
    cp -- "$source_dir/init-latex.sh" "$install_dir/init-latex.sh"
fi

# Single quotes preserve UTF-8 even with macOS Bash 3.2's C locale.
source_path="$install_dir/tex.sh"
quoted_path=${source_path//\'/\'\\\'\'}
source_line="source '$quoted_path'"
if [[ ! -f "$shell_rc" ]] || ! grep -Fqx -- "$source_line" "$shell_rc"; then
    if [[ -f "$shell_rc" && ! -e "$shell_rc.before-tex" ]]; then
        cp -p -- "$shell_rc" "$shell_rc.before-tex"
    fi
    printf '\n# tex: LaTeX project commands (tex init / tex run)\n%s\n' "$source_line" >> "$shell_rc"
fi
printf 'Installed: %s\nShell configuration: %s\nActivate in the current terminal:\n  %s\n' \
    "$install_dir" "$shell_rc" "$source_line"
