#!/usr/bin/env bash
# macOS Bash 3.2+ / Linux. Usage: bash init-latex.sh [project-directory]
# Build settings adapted from research-lab/.vscode/settings.json and
# research-lab/scripts/build_latex.sh; no dependency on the original workspace.
set -euo pipefail

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    printf 'Usage: bash init-latex.sh [project-directory]\nDefault: ./latex-project\nExisting files are preserved, not merged or overwritten.\n'
    exit 0
fi
if (( $# > 1 )); then
    printf 'Error: expected at most one directory argument.\n' >&2
    exit 2
fi

target=${1:-latex-project}
mkdir -p -- "$target"
cd -- "$target"
project_dir=$(pwd -P)
for dir in sections figures refs config scripts .vscode output/.latex_aux; do
    mkdir -p -- "$dir"
done

# Consume each heredoc even when a file already exists.
# noclobber also prevents accidental replacement if another process creates it.
write_new() {
    local path=$1
    if [[ -e "$path" || -L "$path" ]]; then
        printf 'Preserved: %s\n' "$path"
        cat > /dev/null
    else
        (set -o noclobber; cat > "$path")
        printf 'Created:   %s\n' "$path"
    fi
}

write_new .gitignore <<'EOF'
# Generated output (PDF and auxiliary files)
/output/
/build/

# LaTeX auxiliary files, including accidental builds in the source directory
*.aux
*.log
*.out
*.toc
*.lof
*.lot
*.fls
*.fdb_latexmk
*.synctex
*.synctex.gz
*.xdv
*.dvi
*.bbl
*.bcf
*.blg
*.run.xml
*.idx
*.ind
*.ilg
*.acn
*.acr
*.alg
*.glg
*.glo
*.gls
*.glgdefs
*.ist
*.nav
*.snm
*.vrb
*.thm
*.loe
*.lol
/main.pdf

# OS / editor temporary files
.DS_Store
Thumbs.db
*.swp
*.swo
*~

# Python analysis scripts
__pycache__/
*.py[cod]
.venv/
.ipynb_checkpoints/

# Do NOT ignore *.pdf globally: figures/*.pdf are source assets.
# Keep .vscode/settings.json under version control.
EOF

write_new .latexmkrc <<'EOF'
# XeLaTeX, with automatic reruns and Biber when biblatex needs it.
$pdf_mode = 5;
$out_dir = 'output';
$aux_dir = 'output/.latex_aux';
# TeX Live XeLaTeX needs latexmk to emulate a separate auxiliary directory.
$emulate_aux = 1;
$xelatex = 'xelatex -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error %O %S';
$max_repeat = 5;
@default_files = ('main.tex');
EOF

write_new .vscode/settings.json <<'EOF'
{
    "latex-workshop.latex.outDir": "%DIR%/output",
    "latex-workshop.latex.auxDir": "%DIR%/output/.latex_aux",
    "latex-workshop.latex.tools": [
        {
            "name": "latexmk-custom",
            "command": "bash",
            "args": ["%DIR%/scripts/build_latex.sh", "%DOC_EXT%"]
        },
        {
            "name": "xelatex",
            "command": "bash",
            "args": [
                "%DIR%/scripts/build_latex.sh",
                "--xelatex",
                "%DOC_EXT%"
            ]
        }
    ],
    "latex-workshop.latex.recipes": [
        {
            "name": "latexmk (recommended)",
            "tools": ["latexmk-custom"]
        },
        {
            "name": "xelatex (single pass)",
            "tools": ["xelatex"]
        }
    ],
    "latex-workshop.latex.recipe.default": "latexmk (recommended)",
    "latex-workshop.latex.autoBuild.run": "onSave",
    "latex-workshop.latex.autoBuild.interval": 1000,
    "latex-workshop.latex.autoClean.run": "never",
    "latex-workshop.latex.clean.method": "glob",
    "latex-workshop.latex.clean.fileTypes": [
        "*.aux", "*.bbl", "*.bcf", "*.blg", "*.run.xml",
        "*.idx", "*.ind", "*.ilg", "*.lof", "*.lot", "*.out", "*.toc",
        "*.acn", "*.acr", "*.alg", "*.glg", "*.glo", "*.gls", "*.ist",
        "*.fls", "*.log", "*.fdb_latexmk", "*.xdv", "*.dvi",
        "*.nav", "*.snm", "*.vrb"
    ],
    "latex-workshop.view.pdf.viewer": "tab",
    "latex-workshop.intellisense.package.enabled": true,
    "latex-workshop.message.error.show": false,
    "latex-workshop.message.warning.show": false,
    "files.exclude": {
        "**/.DS_Store": true,
        "**/build": true,
        "**/output/.latex_aux": true,
        "**/__pycache__": true
    }
}
EOF

write_new .vscode/extensions.json <<'EOF'
{
    "recommendations": ["James-Yu.latex-workshop"]
}
EOF

write_new scripts/build_latex.sh <<'EOF'
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
EOF

write_new main.tex <<'EOF'
\documentclass[UTF8,a4paper,12pt,fontset=fandol]{ctexart}

\input{config/packages}
\input{config/commands}
\addbibresource{refs/references.bib}

\title{课程报告}
\author{Your Name}
\date{\today}

\begin{document}
\maketitle
\begin{abstract}
    摘要摘要摘要
\end{abstract}
\noindent\textbf{关键词：} 关键词1、关键词2
\tableofcontents
\clearpage

\input{sections/introduction}
\input{sections/theory}
\input{sections/methods}
\input{sections/results}
\input{sections/conclusion}

\printbibliography
\appendix
\counterwithin{figure}{section} 
\renewcommand{\thefigure}{\thesection.\arabic{figure}} 
\setcounter{figure}{0}   
\input{sections/appendix}
\end{document}
EOF

write_new config/packages.tex <<'EOF'
% !TeX root = ../main.tex
\usepackage[margin=2.5cm]{geometry}
\usepackage{amsmath,amssymb,mathtools}
\usepackage{bm}
\usepackage{siunitx}
\usepackage{graphicx}
\usepackage{float}
\usepackage{geometry}
\graphicspath{{figures/}}
\usepackage{booktabs}
\usepackage[backend=biber,style=numeric,sorting=none]{biblatex}
\usepackage[hidelinks]{hyperref}
\usepackage[justification=centering,
            labelfont=bf,
            font=small,
            labelsep=quad,
            skip=5pt]
            {caption}
\usepackage{subcaption}
\usepackage{indentfirst}
\usepackage{threeparttable}
% physics is intentionally omitted: it defines commands such as \dd itself.
EOF

write_new config/commands.tex <<'EOF'
% !TeX root = ../main.tex
\DeclareMathOperator{\Tr}{Tr}
\DeclareMathOperator{\diag}{diag}
\newcommand{\dd}{\mathop{}\!\mathrm{d}}
\newcommand{\vect}[1]{\bm{#1}}
\newcommand{\kb}{k_{\mathrm B}}
EOF

write_new sections/introduction.tex <<'EOF'
% !TeX root = ../main.tex
\section{引言}
在此说明研究背景、目标与报告结构。
引用示例：\cite{example}。请将示例条目替换为真实文献。
EOF

write_new sections/theory.tex <<'EOF'
% !TeX root = ../main.tex
\section{理论基础}
\begin{equation}
    U = \frac{3}{2}N\kb T
\end{equation}
EOF

write_new sections/methods.tex <<'EOF'
% !TeX root = ../main.tex
\section{方法}
在此说明实验方法、数据来源或计算步骤。
EOF

write_new sections/results.tex <<'EOF'
% !TeX root = ../main.tex
\section{结果与讨论}
图片放入 figures/ 后可使用以下代码：
% \begin{figure}[htbp]
%     \centering
%     \includegraphics[width=0.8\linewidth]{spectrum.pdf}
%     \caption{Energy spectrum}
%     \label{fig:spectrum}
% \end{figure}
EOF

write_new sections/conclusion.tex <<'EOF'
% !TeX root = ../main.tex
\section{结论}
在此总结主要结果与后续工作。
EOF

write_new sections/appendix.tex <<'EOF'
% !TeX root = ../main.tex
\section{附录}
在这里添加附录。
EOF

write_new refs/references.bib <<'EOF'
% Placeholder only. Replace this entry with a real bibliographic record.
@misc{example,
    author = {{Example Author}},
    title  = {Placeholder Reference: Replace Before Submission},
    year   = {2026},
    note   = {Template demonstration only; not a real source}
}
EOF

write_new figures/.gitkeep <<'EOF'
EOF

write_new README.md <<'EOF'
# LaTeX 项目

## 环境

- Bash（兼容 macOS 自带的 Bash 3.2）
- TeX 发行版，包含 XeLaTeX、latexmk、Biber
- 宏包：ctex、geometry、amsmath、amssymb、mathtools、bm、siunitx、graphicx、booktabs、biblatex、hyperref、caption、threeparttable etc.
- Fandol 中文字体（模板显式选择 fontset=fandol，避免依赖 macOS 专有字体）
- 可选：VS Code 和 LaTeX Workshop 扩展

脚本只生成文件，不安装软件，不初始化或提交 Git。

## 编译

在本项目根目录运行：

```bash
# 已安装 tex 命令时：
tex run
# 或使用项目自带脚本：
bash scripts/build_latex.sh
# 或直接读取 .latexmkrc：
latexmk main.tex
```

脚本也可以通过绝对路径从其他工作目录调用。
默认编译入口是 main.tex；可传入同一项目根目录下的另一个主文件。

输出 PDF：`output/main.pdf`，对应定位文件为 `output/main.synctex.gz`。
辅助文件在 `output/.latex_aux/`，整个 output/ 不提交 Git。
克隆仓库后该目录可能不存在，构建脚本会自动重建。

VS Code 中请打开整个项目文件夹。保存 .tex 文件会调用默认的
`latexmk (recommended)` 配方，自动执行需要的重复编译和 Biber。
备用 XeLaTeX 配方只编译一遍，不能单独完成参考文献与交叉引用更新。
命令行也可运行 `bash scripts/build_latex.sh --xelatex main.tex`。
两种配方均自动创建输出目录、处理含空格的项目路径，并在失败时返回非零状态。

## 从 research-lab 迁移的配置

来源：research-lab 的 `.vscode/settings.json` 和 `scripts/build_latex.sh`。
原项目未包含 `.latexmkrc`，本文件依据其构建参数补齐。

- 沿用 XeLaTeX、SyncTeX、nonstopmode、file-line-error，以及 PDF 与辅助文件分目录的习惯。
- 沿用保存时自动编译、1000 ms 间隔、标签页预览、宏包补全及错误/警告弹窗偏好。
- 构建命令使用项目自己的脚本，不再写死个人绝对路径。
- 默认采用 latexmk 配方，自动处理参考文献和交叉引用；保留单次 XeLaTeX 配方。
- PDF 预览目录同步为 output/；latexmk 自行管理输出文件，替代原脚本的通配符复制/删除。
- 关闭构建后自动清理，保留增量编译缓存与 SyncTeX，手动 Clean 也不删除定位文件。
- 修正隐藏目录 output/aux 为实际使用的 output/.latex_aux。
- 保留原模板的章节、正文、宏包及参考文献文件；未加入无关的 C/Python 解释器设置。
- `.vscode/settings.json` 和扩展推荐可提交 Git，便于在不同机器上共享项目配置。

脚本仅需 Bash 和常见系统命令即可初始化。编译仍需上述 TeX 环境。

## 文件分工

- main.tex：标题、作者、章节顺序与参考文献
- sections/：正文，每个文件带有指向 ../main.tex 的根文件注释
- figures/：图片，科学绘图建议使用 PDF
- refs/references.bib：参考文献数据库；当前条目仅为演示占位
- config/packages.tex：宏包配置
- config/commands.tex：自定义命令
- scripts/build_latex.sh：定位项目、准备输出目录、调用 latexmk
- .latexmkrc：XeLaTeX 与输出路径的构建配置
- .vscode/settings.json：编辑器编译配方与预览配置

## 清理

不在每次构建后自动清理，以保留增量编译状态与 SyncTeX 定位信息。
需要时，在根目录手动运行：

```bash
latexmk -c main.tex   # 清理辅助文件，保留 PDF
latexmk -C main.tex   # 清理辅助文件和 PDF
```

VS Code 的手动 Clean 命令保留 PDF 和 .synctex.gz。
不要将 *.pdf 全局加入 .gitignore，否则会连同 figures/ 内的源图片一起忽略。

## 初始化脚本的重复运行

只补齐缺失文件；所有已有文件原样保留，不覆盖，也不合并配置。
因此若用于现有项目，请自行检查原有配置与新文件是否兼容。
EOF

# Avoid Bash 3.2's %q emitting mixed raw/escaped UTF-8 bytes in a C locale.
quoted_project=${project_dir//\'/\'\\\'\'}
printf '\nReady: %s\nBuild: cd '\''%s'\'' && bash scripts/build_latex.sh\n' "$project_dir" "$quoted_project"
