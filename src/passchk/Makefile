.PHONY: install clean

UNAME != uname
LDFLAGS-Linux := -lcrypt
LDFLAGS += ${LDFLAGS-${UNAME}}
LD=gcc

EXE := passchk
PREFIX ?= usr

passchk: ${EXE}.c
	${LD} -o $@ $^ ${LDFLAGS}

install: ${DESTDIR}${PREFIX}/bin/${EXE}

$(DESTDIR)$(PREFIX)/bin/$(EXE): ${EXE}
	install -m 755 ${EXE} $@
	${INSTALL_DEP} ${@:${DESTDIR}%=%}

clean:
	rm ${EXE} || true

.PHONY: install clean
