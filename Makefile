OUT=html/BQP.html html/README.html

all: $(OUT)

clean:
	-rm -rf $(OUT)

html/%.html: %.md
	pandoc $< | perl tool/filter-md-html.pl > $@ 
