all: Fonts

.PHONY: Fonts
Fonts:
	$(MAKE) -C Fonts

.PHONY: clean
clean:
	$(MAKE) -C Fonts clean
