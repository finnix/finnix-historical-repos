all: finnix-keyring.gpg

finnix-keyring.gpg: keys/series
	$(CURDIR)/build-keyring $(CURDIR)/keys $(CURDIR)/finnix-keyring.gpg

install:
	install -m 0755 -d $(DESTDIR)/usr/share/keyrings
	install -m 0644 finnix-keyring.gpg $(DESTDIR)/usr/share/keyrings/finnix-keyring.gpg

clean:
	$(RM) finnix-keyring.gpg
