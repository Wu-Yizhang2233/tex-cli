#!/usr/bin/env bash
set -euo pipefail

mode=latexmk
if [[ ${1:-} == --xelatex ]]; then
    mode=xelatex
    shift
fi
if (( $# > 1 )); then
    printf 'Usage: bash scripts/build_latex.sh [--xelatex] [root-document.tex]\n' >&2
    exit 2
fi

# Locate the project from this script, independent of the caller's cwd.
project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd -- "$project_root"

# MacTeX's public symlink, only as a fallback when GUI apps lack its PATH.
if ! command -v latexmk >/dev/null 2>&1 || ! command -v xelatex >/dev/null 2>&1; then
    if [[ -d /Library/TeX/texbin ]]; then
        export PATH="/Library/TeX/texbin:$PATH"
    fi
fi
for tool in "$mode" xelatex; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Missing command: %s. Install a TeX distribution and check PATH.\n' "$tool" >&2
        exit 127
    fi
done

tex_file=${1:-main.tex}
# LaTeX Workshop's %DOC% omits the extension; accept it as well as %DOC_EXT%.
[[ "$tex_file" == *.tex ]] || tex_file="$tex_file.tex"
[[ "$tex_file" == /* ]] || tex_file="$project_root/$tex_file"
if [[ ! -f "$tex_file" ]]; then
    printf 'Document not found: %s\n' "$tex_file" >&2
    exit 1
fi
# The template's sections/config paths are relative to the project root.
tex_dir=$(cd -- "$(dirname -- "$tex_file")" && pwd -P)
if [[ "$tex_dir" != "$project_root" ]]; then
    printf 'Use a root document in the project directory, not a section: %s\n' "$tex_file" >&2
    exit 2
fi
mkdir -p output/.latex_aux
if [[ "$mode" == xelatex ]]; then
    xelatex -synctex=1 -interaction=nonstopmode -file-line-error \
        -halt-on-error -output-directory=output/.latex_aux "$tex_file"
    job_name=$(basename -- "$tex_file" .tex)
    # Copy only this document, and only after a successful compilation.
    cp -- "output/.latex_aux/$job_name.pdf" "output/$job_name.pdf"
    cp -- "output/.latex_aux/$job_name.synctex.gz" "output/$job_name.synctex.gz"
else
    # Same XeLaTeX flags as research-lab; latexmk handles reruns/Biber and
    # places the PDF and SyncTeX in output/, keeping its cache in .latex_aux/.
    exec latexmk -xelatex -synctex=1 -interaction=nonstopmode \
        -file-line-error -halt-on-error \
        -outdir=output -auxdir=output/.latex_aux -emulate-aux-dir "$tex_file"
fi
