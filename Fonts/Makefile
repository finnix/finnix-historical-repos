ALL_FONTS = Lat2-VGA8.psf Lat2-VGA16.psf

fullall: $(ALL_FONTS)

Lat2-VGA8.psf:
	./bdf2psf --log Lat2-VGA8.log bdf/legacy8f.bdf+bdf/legacy8i.bdf+bdf/legacy8b.bdf \
		standard.equivalents ascii.set+linux.set+fontsets/Lat2.256+:useful.set \
		256 Lat2-VGA8.psf Lat2-VGA8.sfm

Lat2-VGA16.psf:
	./bdf2psf --log Lat2-VGA16.log bdf/u_vga16_fix.bdf+bdf/u_vga16.bdf+bdf/legacy16c.bdf+bdf/legacy16k.bdf \
		standard.equivalents ascii.set+linux.set+fontsets/Lat2.256+:useful.set \
		256 Lat2-VGA16.psf Lat2-VGA16.sfm

.PHONY: clean
clean:
	-rm -f *~
	-rm -f *.psf *.psf.gz *.sfm *.log *.raw *.fnt *.scm
	-rm -f fontsets/*~
	-rm -f terminfo termcap
