V=20130406

PREFIX = /usr

install:
	install -dm755 $(DESTDIR)$(PREFIX)/share/pacman/keyrings/
	install -m0644 archbsd{.gpg,-trusted,-revoked} $(DESTDIR)$(PREFIX)/share/pacman/keyrings/

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/share/pacman/keyrings/archbsd{.gpg,-trusted,-revoked}
	rmdir -p --ignore-fail-on-non-empty $(DESTDIR)$(PREFIX)/share/pacman/keyrings/

dist:
	git archive --format=tar --prefix=archbsd-keyring-$(V)/ $(V) | gzip -9 > archbsd-keyring-$(V).tar.gz
	gpg --detach-sign --use-agent archbsd-keyring-$(V).tar.gz

.PHONY: install uninstall dist
