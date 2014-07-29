all: finnix-keyring.gpg finnix-archive-keyring.gpg

finnix-keyring.gpg: keys/finnix-keyring.series
	$(CURDIR)/build-keyring $(CURDIR)/keys $(CURDIR)/keys/finnix-keyring.series $(CURDIR)/finnix-keyring.gpg

finnix-archive-keyring.gpg: keys/finnix-archive-keyring.series
	$(CURDIR)/build-keyring $(CURDIR)/keys $(CURDIR)/keys/finnix-archive-keyring.series $(CURDIR)/finnix-archive-keyring.gpg

install:
	install -m 0755 -d $(DESTDIR)/usr/share/keyrings
	install -m 0644 finnix-keyring.gpg $(DESTDIR)/usr/share/keyrings/finnix-keyring.gpg
	install -m 0644 finnix-archive-keyring.gpg $(DESTDIR)/usr/share/keyrings/finnix-archive-keyring.gpg

clean:
	$(RM) finnix-keyring.gpg finnix-archive-keyring.gpg
