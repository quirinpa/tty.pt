include env.mk

npm-root != npm root
npm-lib := ${npm-lib:%=${npm-root}/%}
npm-lib != echo ${npm-lib} | tr ' ' '\n' | while read lib; do realpath $$lib; done | tr '\n' ' '
LDFLAGS += -L/usr/local/lib
LDFLAGS += ${npm-lib:%=-L%} ${npm-lib:%=-Wl,-rpath,%}
CFLAGS += -I/usr/local/include
CFLAGS += ${npm-lib:%=-I%/include}

bin := $(exe:%=$(DESTDIR)$(PREFIX)/bin/%)

$(bin): ${exe:%=%.c}
	@install -d ${DESTDIR}${PREFIX}/bin
	${CC} ${CFLAGS} -o $@ ${@:${DESTDIR}${PREFIX}/bin/%=%.c} ${LDFLAGS}

install: ${exe:%=${DESTDIR}${PREFIX}/bin/%}

clean:
	rm ${exe:%=${DESTDIR}${PREFIX}/bin/%} || true

.PHONY: install clean
