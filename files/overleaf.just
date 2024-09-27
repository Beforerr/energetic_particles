overleaf_repo := x'https://git@git.overleaf.com/$OVERLEAF_ID'

clone_overleaf:
  git clone {{overleaf_repo}} overleaf

update_overleaf: sync_overleaf
  cd overleaf; git add .; git commit -am "update"; git push

sync_overleaf: tex_render tex_keep_document tex_export_bib tex_clean

tex_render:
  #!/usr/bin/env bash
  touch files/bibexport.bib
  quarto render --profile man --to $OVERLEAF_FMT
  rsync _manuscript/_tex/ overleaf/ -r
  rsync article_files overleaf -r

[private]
tex_export_bib:
  #!/usr/bin/env bash
  command -v bibexport >/dev/null || tlmgr install bibexport
  bibexport -o files/bibexport.bib --nosave article.aux

[private]
tex_keep_document:
  #!/usr/bin/env bash
  temp_file=$(mktemp)
  awk '/\\begin\{document\}/ {flag=1; next} /\\end\{document\}/ {flag=0} flag' overleaf/article.tex | awk '!/\\maketitle/' > $temp_file
  mv $temp_file overleaf/article.tex

[private]
tex_clean:
  -rm article.{aux,bbl,blg,log,tex}
  -rm trackchanges.sty *.cls