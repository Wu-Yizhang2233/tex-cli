import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class CliTests(unittest.TestCase):
    def test_source_exposes_texv_without_overwriting_tex(self):
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell):
                cmd = 'tex() { printf original; }; source "$1"; texv --help; tex'
                result = subprocess.run([shell, '-c', cmd, '_', str(ROOT/'tex.sh')], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('Usage: texv <command>', result.stdout)
                self.assertTrue(result.stdout.endswith('original'))

    def test_init_creates_project_and_changes_shell_directory(self):
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as tmp:
                target = Path(tmp) / '中文 report'
                cmd = 'source "$1"; texv init "$2" >/dev/null; printf "\\nCWD=%s" "$PWD"'
                p = subprocess.run([shell, '-c', cmd, '_', str(ROOT/'tex.sh'), str(target)], text=True, capture_output=True)
                self.assertEqual(p.returncode, 0, p.stderr)
                self.assertIn('CWD='+str(target), p.stdout)
                self.assertTrue((target/'scripts/build_latex.sh').is_file())
                self.assertTrue((target/'README.md').is_file())

    def test_run_finds_root_and_propagates_build_status(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); (root/'scripts').mkdir(); (root/'sections').mkdir()
            (root/'main.tex').touch()
            (root/'scripts/build_latex.sh').write_text('printf "%s|%s" "$PWD" "$*"; exit 17\n')
            p = subprocess.run(['python3', str(ROOT/'tex_cli.py'), 'run', '--xelatex', 'a b.tex'], cwd=root/'sections', capture_output=True, text=True)
            self.assertEqual(p.returncode, 17, p.stderr)
            self.assertEqual(p.stdout, str(root.resolve())+'|--xelatex a b.tex')

if __name__ == '__main__': unittest.main()

class ProjectTypeTests(unittest.TestCase):
    def test_mini_has_one_tex_file_and_shared_configuration(self):
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as tmp:
                target = Path(tmp) / 'mini 中文'
                cmd = 'source "$1"; texv init --mini "$2" >/dev/null; printf "%s" "$PWD"'
                result = subprocess.run([shell, '-c', cmd, '_', str(ROOT/'tex.sh'), str(target)], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, str(target))
                self.assertEqual([str(p.relative_to(target)) for p in target.rglob('*.tex')], ['main.tex'])
                for f in ('.gitignore', '.latexmkrc', '.vscode/settings.json', 'scripts/build_latex.sh'):
                    self.assertTrue((target/f).is_file(), f)
                self.assertFalse((target/'sections').exists())

    def test_unknown_type_fails_without_creating_project(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp)/'project'
            result = subprocess.run(['python3', str(ROOT/'tex_cli.py'), 'init', '--unknown', str(target)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(target.exists())

class CollisionTests(unittest.TestCase):
    def test_mini_default_and_numbered_collision_in_shells(self):
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as tmp:
                base = Path(tmp)
                (base/'mini-project').mkdir()
                (base/'mini-project'/'main.tex').write_text('original')
                (base/'mini-project(1)').mkdir()
                cmd = 'source "$1"; cd "$2"; texv init --mini >/dev/null; printf "%s" "$PWD"'
                result = subprocess.run([shell, '-c', cmd, '_', str(ROOT/'tex.sh'), tmp], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(Path(result.stdout).resolve(), (base/'mini-project(2)').resolve())
                self.assertEqual((base/'mini-project'/'main.tex').read_text(), 'original')
                self.assertTrue((base/'mini-project(2)'/'main.tex').is_file())

    def test_existing_custom_path_gets_suffix(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)/'中文 名'
            path.mkdir()
            result = subprocess.run(['python3', str(ROOT/'tex_cli.py'), 'init', str(path)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse((path/'main.tex').exists())
            self.assertTrue((Path(str(path)+'(1)')/'main.tex').is_file())

class ColorTests(unittest.TestCase):
    def test_terminal_color_and_no_color(self):
        import importlib.util
        from unittest.mock import patch
        spec = importlib.util.spec_from_file_location('tex_cli', ROOT/'tex_cli.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        class Terminal:
            def isatty(self): return True
        with patch.dict(os.environ, {'TERM': 'xterm-256color'}, clear=True):
            self.assertEqual(module.styled('Error:', '31', Terminal()), "\x1b[31mError:\x1b[0m")
        with patch.dict(os.environ, {'TERM': 'xterm-256color', 'NO_COLOR': '1'}, clear=True):
            self.assertEqual(module.styled('Error:', '31', Terminal()), 'Error:')
        with patch.dict(os.environ, {'TERM': 'dumb'}, clear=True):
            self.assertEqual(module.styled('Error:', '31', Terminal()), 'Error:')

    def test_redirected_output_has_no_escape_sequences(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(['python3', str(ROOT/'tex_cli.py'), 'init', '--mini', str(Path(tmp)/'project')], capture_output=True)
            self.assertEqual(result.returncode, 0)
            self.assertNotIn(b'\x1b[', result.stdout + result.stderr)

class SlidesTests(unittest.TestCase):
    def test_default_name_and_structure_for_both_shells(self):
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as tmp:
                command = 'source "$1"; cd "$2"; texv init --slides >/dev/null && printf "%s" "$PWD"'
                result = subprocess.run([shell, '-c', command, '_', str(ROOT/'tex.sh'), tmp], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                project = Path(tmp)/'slides-project'
                self.assertEqual(Path(result.stdout).resolve(), project.resolve())
                for name in ('main.tex', 'sections/introduction.tex', 'figures/.gitkeep', '.vscode/settings.json', '.latexmkrc', '.gitignore', 'scripts/build_latex.sh'):
                    self.assertTrue((project/name).is_file(), name)
                self.assertIn('beamer', (project/'main.tex').read_text())

    def test_slides_help_and_collision(self):
        help_result = subprocess.run(['python3', str(ROOT/'tex_cli.py'), 'init', '--help'], capture_output=True, text=True)
        self.assertIn('--slides', help_result.stdout)
        self.assertIn('slides-project', help_result.stdout)
        with tempfile.TemporaryDirectory() as tmp:
            existing = Path(tmp)/'slides-project'; existing.mkdir()
            result = subprocess.run(['python3', str(ROOT/'tex_cli.py'), 'init', '--slides'], cwd=tmp, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((Path(tmp)/'slides-project(1)'/'main.tex').is_file())
            self.assertFalse((existing/'main.tex').exists())

    def test_invalid_type_returns_status_in_zsh(self):
        cmd = 'source "$1"; texv init --unknown >/dev/null; exit $?'
        result = subprocess.run(['zsh', '-c', cmd, '_', str(ROOT/'tex.sh')], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertNotIn('read-only variable', result.stderr)
