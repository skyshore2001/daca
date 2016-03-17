all: html/BQP.html html/README.html

html/%.html: %.md h.inc
	pandoc -f markdown -t html -s --toc -N -H h.inc -o $@ $<
