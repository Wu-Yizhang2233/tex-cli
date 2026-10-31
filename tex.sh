# Source in Bash or zsh: changing the caller's directory requires a shell function.
if [ -n "${ZSH_VERSION:-}" ]; then
    _TEX_CLI_HOME=$(builtin cd -- "$(command dirname -- "${(%):-%x}")" && pwd -P) || return
elif [ -n "${BASH_VERSION:-}" ]; then
    _TEX_CLI_HOME=$(builtin cd -- "$(command dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || return
else
    printf 'tex requires Bash or zsh.\n' >&2
    return 1
fi

function tex {
    if [ "${1:-}" = init ]; then
        shift
        case "${1:-}" in
            -h|--help) command python3 "$_TEX_CLI_HOME/tex_cli.py" init "$@"; return $? ;;
        esac
        local project_path
        if [ "${1:-}" = -- ]; then
            project_path=${2:-latex-project}
        else
            project_path=${1:-latex-project}
        fi
        if command python3 "$_TEX_CLI_HOME/tex_cli.py" init "$@"; then
            builtin cd -- "$project_path"
        else
            return $?
        fi
    else
        command python3 "$_TEX_CLI_HOME/tex_cli.py" "$@"
    fi
}
