# tex 命令行工具

## 安装与使用

在本仓库根目录运行 `bash install-tex.sh`。工具复制到
`~/.local/share/tex-cli/`，并在 `${ZDOTDIR:-$HOME}/.zshrc` 中添加加载行。
首次修改前将已有配置备份到 `.zshrc.before-tex`；重复安装不会重复追加加载行。
安装后打开新终端，或在当前终端执行安装程序输出的 `source` 命令。

```bash
tex init                  # 创建 latex-project/ 并进入
tex init my-paper         # 创建 my-paper/ 并进入
tex init "中文报告"        # 支持中文、空格和绝对路径
tex run                   # 编译 main.tex
tex run report.tex        # 编译项目根目录中的另一个主文件
tex run --xelatex         # 只运行一遍 XeLaTeX
tex --help
```

`tex init` 调用配套的 `init-latex.sh`；重复初始化只补齐缺失文件。
`tex run` 向上寻找最近的项目根目录，调用该项目的 `scripts/build_latex.sh`，
保持项目自己的编译规则，并传递编译退出状态。在 sections/ 等子目录也可运行。
模板默认输出 `output/main.pdf`，辅助文件放入 `output/.latex_aux/`。

## 实现与更新

`tex` 是一个 Bash/zsh 函数：只有在当前 shell 中执行，`tex init` 才能让
当前终端切换目录。普通独立可执行文件无法修改父 shell 的工作目录。
工具自身不修改 shell 的 `set -e`、`set -u` 等选项。

安装包由 `tex.sh` 和 `init-latex.sh` 组成，构建脚本已内嵌在初始化脚本中，
创建项目时写出。运行时无需 Python、网络或原仓库目录；编译需要 MacTeX/TeX Live。
修改仓库中的模板后，重新运行 `bash install-tex.sh` 即可更新安装副本。
现有项目中的文件不会被更新安装覆盖。

不安装也可直接 `source /绝对路径/research-lab/tex.sh` 使用最新源码。
安装至其他位置或使用 Bash 时，显式传入目标目录和启动文件：

```bash
bash install-tex.sh ~/.local/share/tex-cli ~/.bashrc
# macOS 登录 Bash 可使用 ~/.bash_profile
```

MacTeX 已有一个名为 `tex` 的底层引擎。安装后交互终端中的 `tex` 指向本工具；
`command tex` 仍可调用原引擎，系统可执行文件和 PATH 均未改动。

卸载时删除启动文件中标注 `tex: LaTeX project commands` 的注释及紧随其后的
source 行，再删除安装目录；当前终端可执行 `unset -f tex`。

## 验证

`python3 -m unittest discover -s tests -p 'test_tex_cli.py' -v` 检查 Bash/zsh
下的目录切换、默认名称、路径引用、已有文件保留、失败返回以及独立安装。
