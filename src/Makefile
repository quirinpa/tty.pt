ROOT=/var/www

mpfd: mpfd.c
	${CC} -o $@ mpfd.c

install: mpfd
	${INSTALL} mpfd ${ROOT}/usr/bin

.PHONY: install
