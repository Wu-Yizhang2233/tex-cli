# XeLaTeX, with automatic reruns and Biber when biblatex needs it.
$pdf_mode = 5;
$out_dir = 'output';
$aux_dir = 'output/.latex_aux';
# TeX Live XeLaTeX needs latexmk to emulate a separate auxiliary directory.
$emulate_aux = 1;
$xelatex = 'xelatex -synctex=1 -interaction=nonstopmode -file-line-error -halt-on-error %O %S';
$max_repeat = 5;
@default_files = ('main.tex');
