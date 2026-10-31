import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class CliTests(unittest.TestCase):
    def test_init_preserves_files_and_changes_shell_directory(self):
        for shell in ('bash', 'zsh'):
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as tmp:
                target = Path(tmp) / '中文 report'
                target.mkdir()
                (target / 'main.tex').write_text('keep')
                cmd = 'source "$1"; tex init "$2" >/dev/null; printf "\\nCWD=%s" "$PWD"'
                p = subprocess.run([shell, '-c', cmd, '_', str(ROOT/'tex.sh'), str(target)], text=True, capture_output=True)
                self.assertEqual(p.returncode, 0, p.stderr)
                self.assertIn('CWD='+str(target), p.stdout)
                self.assertEqual((target/'main.tex').read_text(), 'keep')
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
