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
# 已安装 texv 命令时：
texv run
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
