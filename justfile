import 'files/quarto.just'

default:
    just --list

ensure-env:
    julia --project=. -e 'using Pkg; Pkg.develop("Beforerr")'
    rsync --update --recursive ~/projects/share/quarto/ ./

render:
    quarto render prep.qmd --to pptx