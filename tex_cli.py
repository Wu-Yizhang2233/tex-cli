#!/usr/bin/env python3
"""LaTeX project creation and build commands."""
import os
from pathlib import Path
import subprocess
import sys

HOME = Path(__file__).resolve().parent
USAGE = '''Usage: texv <command>
  texv init [--mini|--slides] [directory]   Create and enter a project
  texv run [--xelatex] [main.tex]   Compile the current project
  texv --help                      Show this help
Existing names get a numbered suffix.'''


# Add new project types here; each type lists paths from the shared template.
COMMON_FILES = ('.gitignore', '.latexmkrc', '.vscode/settings.json',
                '.vscode/extensions.json', 'scripts/build_latex.sh')
PROJECT_TYPES = {
    'default': None,  # All files in templates/ preserve the original layout.
    'mini': COMMON_FILES,
    'slides': COMMON_FILES,
}


def styled(text, color, stream):
    """Color interactive output without adding escape codes to redirected text."""
    if stream.isatty() and not os.environ.get('NO_COLOR') and os.environ.get('TERM') != 'dumb':
        return f'\033[{color}m{text}\033[0m'
    return text


def message(label, detail, color, stream):
    print(f'{styled(label, color, stream)} {detail}', file=stream)


def init(args):
    usage = ('Usage: texv init [--mini|--slides] [directory]\n'
             'Defaults: latex-project (standard), mini-project (--mini), slides-project (--slides).\n'
             'Existing names get a numbered suffix.')
    if args and args[0] in ('-h', '--help'):
        print(usage)
        return 0
    project_type = 'default'
    if args and args[0].startswith('--') and args[0] != '--':
        project_type = args[0][2:]
        args = args[1:]
        if project_type not in PROJECT_TYPES:
            message('Error:', f'Unknown project type: --{project_type}\n{usage}', '31', sys.stderr)
            return 2
    if args and args[0] == '--':
        args = args[1:]
    if len(args) > 1 or (args and not args[0]):
        message('Error:', usage, '31', sys.stderr)
        return 2
    default_name = {'default': 'latex-project', 'mini': 'mini-project', 'slides': 'slides-project'}[project_type]
    requested = Path(args[0] if args else default_name).absolute()
    try:
        shared = HOME / 'templates'
        selection = PROJECT_TYPES[project_type]
        files = ([p for p in shared.rglob('*') if p.is_file()] if selection is None
                 else [shared / name for name in selection])
        sources = [(p.relative_to(shared), p) for p in files]
        if project_type != 'default':
            overlay = HOME / 'project_types' / project_type
            sources += [(p.relative_to(overlay), p) for p in overlay.rglob('*') if p.is_file()]
        requested.parent.mkdir(parents=True, exist_ok=True)
        number = 0
        while True:
            target = requested if number == 0 else requested.with_name(f'{requested.name}({number})')
            try:
                target.mkdir()
                break
            except FileExistsError:
                if number == 0:
                    message('Warning:', f'Project path already exists: {requested}; choosing a new name.', '33', sys.stderr)
                number += 1
        (target / 'output/.latex_aux').mkdir(parents=True, exist_ok=True)
        for relative, template in sorted(sources):
            destination = target / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            try:
                with destination.open('xb') as out:
                    out.write(template.read_bytes())
                message('Created:', f'  {relative}', '32', sys.stdout)
            except FileExistsError:
                message('Preserved:', str(relative), '33', sys.stdout)
        result_file = os.environ.get('TEX_CLI_RESULT_FILE')
        if result_file:
            Path(result_file).write_text(str(target) + '\n', encoding='utf-8')
        print()
        message('Ready:', str(target.resolve()), '32', sys.stdout)
        return 0
    except OSError as exc:
        message('Error:', f'Initialization failed: {exc}', '31', sys.stderr)
        return 1


def run(args):
    if args and args[0] in ('-h', '--help'):
        print('Usage: texv run [--xelatex] [main.tex]\nBuild using the nearest project scripts/build_latex.sh.')
        return 0
    current = Path.cwd()
    for root in (current, *current.parents):
        if (root / 'scripts/build_latex.sh').is_file() and ((root / 'main.tex').is_file() or (root / '.latexmkrc').is_file()):
            try:
                result = subprocess.run(['bash', 'scripts/build_latex.sh', *(args or ['main.tex'])], cwd=root)
                return 128 - result.returncode if result.returncode < 0 else result.returncode
            except OSError as exc:
                message('Error:', f'Build failed: {exc}', '31', sys.stderr)
                return 1
    message('Error:', 'No LaTeX project found. Use texv init [directory] first.', '31', sys.stderr)
    return 1


def main(args):
    if not args or args[0] in ('-h', '--help', 'help'):
        print(USAGE)
        return 0
    if args[0] == 'init':
        return init(args[1:])
    if args[0] == 'run':
        return run(args[1:])
    message('Error:', f'Unknown command: {args[0]}. Use texv --help.', '31', sys.stderr)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
