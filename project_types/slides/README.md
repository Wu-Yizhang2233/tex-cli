# LaTeX 幻灯片项目

本模板使用 Beamer 和 XeLaTeX，默认页面比例为 16:9。
编辑 `main.tex` 中的标题、作者及章节顺序；在 `sections/` 中编写幻灯片，图片放在 `figures/`。

运行 `texv run` 或 `bash scripts/build_latex.sh` 编译。生成的 PDF 和 SyncTeX 位于 `output/`，中间文件位于 `output/.latex_aux/`。VS Code 可使用 LaTeX Workshop 项目配置。

模板使用 Fandol 中文字体，需安装 XeLaTeX、latexmk、beamer 和 ctex。默认保留中间文件以支持增量编译；需要时可用 `latexmk -c main.tex` 手动清理。
