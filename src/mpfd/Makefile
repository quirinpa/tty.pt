PREFIX ?= usr

mpfd: mpfd.c
	${CC} -o $@ mpfd.c

install: ${DESTDIR}${PREFIX}/bin/mpfd

$(DESTDIR)$(PREFIX)/bin/mpfd: mpfd
	install -m 755 mpfd $@
	${INSTALL_DEP} ${@:${DESTDIR}%=%}

clean:
	rm mpfd || true

.PHONY: install clean
