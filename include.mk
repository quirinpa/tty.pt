include env.mk

npm-root != npm root
prefix := ${pwd} \
	  ${npm-lib:%=${npm-root}/%} \
	  ${npm-lib:%=${npm-root-dir}/../../%} \
	  /usr/local
CFLAGS += -g ${prefix:%=-I%/include}
LDFLAGS	+= ${prefix:%=-L%/lib} ${prefix:%=-Wl,-rpath,%/lib}

bin := $(exe:%=$(DESTDIR)$(PREFIX)/bin/%)

$(bin): ${exe:%=%.c}
	echo ROOT ${npm-root}
	@install -d ${DESTDIR}${PREFIX}/bin
	${CC} ${CFLAGS} -o $@ ${@:${DESTDIR}${PREFIX}/bin/%=%.c} ${LDFLAGS}

install: ${exe:%=${DESTDIR}${PREFIX}/bin/%}

clean:
	rm ${exe:%=${DESTDIR}${PREFIX}/bin/%} || true

.PHONY: install clean
