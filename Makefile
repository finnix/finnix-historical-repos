PREFIX = /usr/local
SBINDIR = $(PREFIX)/sbin
DATAROOTDIR = $(PREFIX)/share
MANDIR = $(DATAROOTDIR)/man
CFLAGS = -O2 -Wall -Werror

all: finnix-utmp

install:
	install -d -m 0755 $(DESTDIR)$(SBINDIR)
	install -m 0755 finnix-utmp $(DESTDIR)$(SBINDIR)/finnix-utmp
	install -d -m 0755 $(DESTDIR)$(MANDIR)/man8
	install -m 0644 finnix-utmp.8 $(DESTDIR)$(MANDIR)/man8/finnix-utmp.8

clean:
	$(RM) finnix-utmp

doc: finnix-utmp.8

finnix-utmp.8: finnix-utmp.pod
	pod2man -c '' -r '' -s 8 $< >$@

doc-clean:
	$(RM) finnix-utmp.8
