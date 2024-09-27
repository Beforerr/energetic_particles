import 'files/quarto.just'

default:
  just --list

ensure-env:
  rsync --update --recursive ~/projects/share/quarto/ ./