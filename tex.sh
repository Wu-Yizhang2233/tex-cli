# Source this file in Bash or zsh: tex init must cd in the calling shell.
# init-latex.sh lives beside this file and embeds the project build script.
if [ -n "${ZSH_VERSION:-}" ]; then
    _TEX_CLI_HOME=$(builtin cd -- "$(command dirname -- "${(%):-%x}")" && pwd -P) || return
elif [ -n "${BASH_VERSION:-}" ]; then
    _TEX_CLI_HOME=$(builtin cd -- "$(command dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || return
else
    printf 'tex requires Bash or zsh.\n' >&2
    return 1
fi

function tex {
    local action=${1:---help}
    if [ "$#" -gt 0 ]; then shift; fi
    case "$action" in
        init)
            case "${1:-}" in
                -h|--help)
                    printf 'Usage: tex init [directory]\nDefault: latex-project. Creates the project, then changes into it.\n'
                    return 0
                    ;;
                --) shift ;;
            esac
            if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ -z "$1" ]; }; then
                printf 'Usage: tex init [directory]\n' >&2
                return 2
            fi
            local project_path=${1:-latex-project}
            case "$project_path" in
                /*) ;;
                *) project_path="$PWD/$project_path" ;;
            esac
            # No eval, no parsing stdout, and no cwd change when init fails.
            if command bash "$_TEX_CLI_HOME/init-latex.sh" "$project_path"; then
                builtin cd -- "$project_path"
            else
                return $?
            fi
            ;;
        run)
            case "${1:-}" in
                -h|--help)
                    printf 'Usage: tex run [--xelatex] [main.tex]\nBuild using the nearest project scripts/build_latex.sh.\n'
                    return 0
                    ;;
            esac
            local project_root=$PWD
            while :; do
                if [ -f "$project_root/scripts/build_latex.sh" ] &&
                   { [ -f "$project_root/main.tex" ] || [ -f "$project_root/.latexmkrc" ]; }; then
                    break
                fi
                if [ "$project_root" = / ]; then
                    printf 'No LaTeX project found. Use tex init [directory] first.\n' >&2
                    return 1
                fi
                project_root=$(command dirname -- "$project_root") || return
            done
            if [ "$#" -eq 0 ]; then set -- main.tex; fi
            # Run from the project root but keep the caller's cwd unchanged.
            (builtin cd -- "$project_root" && command bash scripts/build_latex.sh "$@")
            ;;
        -h|--help|help)
            printf '%s\n' \
                'Usage: tex <command>' \
                '  tex init [directory]            Create and cd into a project (default: latex-project)' \
                '  tex run [--xelatex] [main.tex]   Compile the current project' \
                '  tex --help                      Show this help' \
                'Existing project files are preserved. Use command tex for the original TeX engine.'
            ;;
        *)
            printf 'Unknown command: %s. Use tex --help.\n' "$action" >&2
            return 2
            ;;
    esac
}
