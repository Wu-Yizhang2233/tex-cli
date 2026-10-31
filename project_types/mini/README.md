# LaTeX 小型项目

正文放在 `main.tex`。运行 `tex run`，或运行 `bash scripts/build_latex.sh` 编译。
PDF 和 SyncTeX 文件位于 `output/`，中间文件位于 `output/.latex_aux/`。
VS Code 可使用 LaTeX Workshop 的项目配置。编译需要 XeLaTeX、latexmk 和 Biber。
`latexmk -c main.tex` 可手动清理中间文件；默认保留这些文件以支持增量编译。
