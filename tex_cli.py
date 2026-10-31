#!/usr/bin/env python3
"""LaTeX project creation and build commands."""
import os
from pathlib import Path
import subprocess
import sys

HOME = Path(__file__).resolve().parent
USAGE = '''Usage: tex <command>
  tex init [directory]            Create and cd into a project (default: latex-project)
  tex run [--xelatex] [main.tex]   Compile the current project
  tex --help                      Show this help
Existing project files are preserved. Use command tex for the original TeX engine.'''


def init(args):
    if args and args[0] in ('-h', '--help'):
        print('Usage: tex init [directory]\nDefault: latex-project. Creates the project, then changes into it.')
        return 0
    if args and args[0] == '--':
        args = args[1:]
    if len(args) > 1 or (args and not args[0]):
        print('Usage: tex init [directory]', file=sys.stderr)
        return 2
    target = Path(args[0] if args else 'latex-project').absolute()
    try:
        target.mkdir(parents=True, exist_ok=True)
        for directory in ('sections', 'figures', 'refs', 'config', 'scripts', '.vscode', 'output/.latex_aux'):
            (target / directory).mkdir(parents=True, exist_ok=True)
        for template in sorted((HOME / 'templates').rglob('*')):
            if not template.is_file():
                continue
            relative = template.relative_to(HOME / 'templates')
            destination = target / relative
            try:
                with destination.open('xb') as out:
                    out.write(template.read_bytes())
                print(f'Created:   {relative}')
            except FileExistsError:
                print(f'Preserved: {relative}')
        print(f'\nReady: {target.resolve()}')
        return 0
    except OSError as exc:
        print(f'Initialization failed: {exc}', file=sys.stderr)
        return 1


def run(args):
    if args and args[0] in ('-h', '--help'):
        print('Usage: tex run [--xelatex] [main.tex]\nBuild using the nearest project scripts/build_latex.sh.')
        return 0
    current = Path.cwd()
    for root in (current, *current.parents):
        if (root / 'scripts/build_latex.sh').is_file() and ((root / 'main.tex').is_file() or (root / '.latexmkrc').is_file()):
            try:
                result = subprocess.run(['bash', 'scripts/build_latex.sh', *(args or ['main.tex'])], cwd=root)
                return 128 - result.returncode if result.returncode < 0 else result.returncode
            except OSError as exc:
                print(f'Build failed: {exc}', file=sys.stderr)
                return 1
    print('No LaTeX project found. Use tex init [directory] first.', file=sys.stderr)
    return 1


def main(args):
    if not args or args[0] in ('-h', '--help', 'help'):
        print(USAGE)
        return 0
    if args[0] == 'init':
        return init(args[1:])
    if args[0] == 'run':
        return run(args[1:])
    print(f'Unknown command: {args[0]}. Use tex --help.', file=sys.stderr)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
