.PHONY: install clean

UNAME != uname
LDFLAGS-Linux := -lcrypt -lqhash -g
LDFLAGS += ${LDFLAGS-${UNAME}} -L/usr/local/lib
LD=gcc

EXE := htpasswd
PREFIX ?= usr

$(EXE): ${EXE}.c
	${LD} -o $@ $^ ${LDFLAGS}

install: ${DESTDIR}${PREFIX}/bin/${EXE}

$(DESTDIR)$(PREFIX)/bin/$(EXE): ${EXE}
	install -m 755 ${EXE} $@
	${INSTALL_DEP} ${@:${DESTDIR}%=%}

clean:
	rm ${EXE} || true

.PHONY: install clean
