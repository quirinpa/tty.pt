DOCUMENT_ROOT=/var/www

all: mpfd crypt_checkpass

mpfd: mpfd.c
	${CC} -o $@ mpfd.c

crypt_checkpass: crypt_checkpass.c
	${CC} -o $@ crypt_checkpass.c

install: mpfd crypt_checkpass
	${INSTALL} mpfd ${DOCUMENT_ROOT}/usr/bin
	${INSTALL} crypt_checkpass ${DOCUMENT_ROOT}/usr/bin

.PHONY: install all
