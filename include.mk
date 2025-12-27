include env.mk

prefix := ${pwd} /usr/local
CFLAGS += -g ${prefix:%=-I%/include}
LDFLAGS	+= ${prefix:%=-L%/lib}

bin := $(exe:%=$(DESTDIR)$(PREFIX)/bin/%)

$(bin): ${exe:%=src/%.c}
	@install -d ${DESTDIR}${PREFIX}/bin
	${CC} ${CFLAGS} -o $@ ${@:${DESTDIR}${PREFIX}/bin/%=src/%.c} ${LDFLAGS}

install: ${exe:%=${DESTDIR}${PREFIX}/bin/%}

clean:
	rm ${exe:%=${DESTDIR}${PREFIX}/bin/%} || true

.PHONY: install clean
