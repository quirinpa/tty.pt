include env.mk

LDFLAGS += -L/usr/local/lib
CFLAGS += -I/usr/local/include

bin := $(exe:%=$(DESTDIR)$(PREFIX)/bin/%)

$(bin): ${exe:%=%.c}
	@install -d ${DESTDIR}${PREFIX}/bin
	${CC} -o $@ ${@:${DESTDIR}${PREFIX}/bin/%=%.c} ${LDFLAGS} ${CFLAGS}

install: ${exe:%=${DESTDIR}${PREFIX}/bin/%}

clean:
	rm ${exe:%=${DESTDIR}${PREFIX}/bin/%} || true

.PHONY: install clean
