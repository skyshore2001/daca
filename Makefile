all: BQP.html README.html

%.html: %.md h.inc
	pandoc -f markdown -t html -s --toc -N -H h.inc -o $@ $<
