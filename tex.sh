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
        local project_path result_file tex_status
        result_file=$(command mktemp "${TMPDIR:-/tmp}/tex-cli.XXXXXXXX") || return 1
        if TEX_CLI_RESULT_FILE="$result_file" command python3 "$_TEX_CLI_HOME/tex_cli.py" init "$@"; then
            IFS= read -r project_path < "$result_file"
            command rm -f -- "$result_file"
            builtin cd -- "$project_path"
        else
            tex_status=$?
            command rm -f -- "$result_file"
            return "$tex_status"
        fi
    else
        command python3 "$_TEX_CLI_HOME/tex_cli.py" "$@"
    fi
}
