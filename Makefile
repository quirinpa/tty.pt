include common.mk
src-y != ls src
DESTDIR := ${PWD}/
PREFIX := usr
INSTALL_DEP := ${PWD}/make_dep.sh
MAKEFLAGS += INSTALL_DEP=${INSTALL_DEP} DESTDIR=${PWD}/
MFLAGS := ${MAKEFLAGS}
mod-y != cat .modules | while read line; do basename $$line | sed s/\\..*//; done
mod-dirs := ${mod-y:%=items/%}
chown-user := www
chown-group := www
chown-dirs-OpenBSD := sessions
chown-dirs := ${chown-dirs-${uname}}
chroot_mkdir := empty sessions
sudo-Linux := sudo
sudo-OpenBSD := doas
sudo := ${sudo-${uname}}
sudo-root := ${sudo}
LDFLAGS := -L/usr/local/lib
CFLAGS := -I/usr/local/include
lcrypt-Linux := -lcrypt
lcrypt := ${lcrypt-${uname}}
all-Linux := etc/shadow
all-OpenBSD := etc/pwd.db
# please change the default if online
root-password := unsafe
shell-OpenBSD := /bin/ksh
shell-Linux := /bin/bash
shell := ${shell-${uname}}
no-shell := /sbin/nologin

all:

chroot: users/ home/

htdocs/vim.css: FORCE
	@${MAKE} -C htdocs/vss

bin/htpasswd: src/htpasswd/htpasswd.c
	@mkdir bin 2>/dev/null || true
	${LINK.c} -o $@ src/htpasswd/htpasswd.c -lqhash -ldb ${lcrypt}

bin/htmlsh: src/htmlsh/htmlsh.c
	@mkdir bin 2>/dev/null || true
	${LINK.c} -o $@ src/htmlsh/htmlsh.c

bin/mpfd: src/mpfd/mpfd.c
	@mkdir bin 2>/dev/null || true
	${LINK.c} -o $@ src/mpfd/mpfd.c

src-bin := htpasswd htmlsh mpfd
src-bin := ${src-bin:%=bin/%}

-include .all-install
mod-bin := ${mod-bin:%=bin/%}

mod-bin:
	@echo ${mod-y} | tr ' ' '\n' | while read mod; do \
		${MAKE} module=$$mod DESTDIR=${PWD}/ \
		-f ${PWD}/module.mk; done
		
mod-dirs:
	@mkdir items 2>/dev/null || true
	@cat .modules | while read line; do \
		dir=`basename $$line | sed 's/\..*//'` ; \
		test -d items/$$dir || git -C items clone --recursive $$dir ; \
		done

.all-install: .links install
	@cp install .all-install
	@ls items | while read module; do \
		test ! -f items/$$module/install || cat items/$$module/install; \
		done >> .all-install
	@cat .all-install | while read dep ign; do \
		test -f $$dep && echo $$dep || which $$dep 2>/dev/null; \
		done | while read dep; do ./rldd $$dep ; done | sort -u > .all-install

items: FORCE
	mkdir $@ || true

all: .all-install mod-dirs chroot htdocs/vim.css ${all-${uname}} etc/group etc/passwd \
	etc/resolv.conf mod-bin ${src-bin}

etc/group:
	echo "wheel:*:0:root" > $@
	echo "_shadow:*:65:" >> $@
	chmod 644 $@
	${sudo} chown root:wheel $@

etc/passwd:
	echo "root:X:0:0:root:/root:${shell}" > $@
	echo "daemon:*:1:1:root:/root:${no-shell}" >> $@
	chmod 644 $@
	${sudo} chown root:wheel $@

etc/shadow etc/master.passwd:
	test "${root-password}" != "unsafe" \
		|| echo Warning: default password is unsafe >&2
	echo "`./bin/htpasswd root ${root-password}`:0:0:daemon:0:0:Charlie &:/root:${shell}" > $@
	echo "daemon:*:1:1::0:0:The devil will die:/root:/sbin/nologin" >> $@
	chmod 600 $@
	${sudo} chown root:wheel $@

etc/pwd.db: etc/group etc/master.passwd
	${sudo} chroot . pwd_mkdb /etc/master.passwd

${chroot-cp}:
	@mkdir -p `dirname $@` || true
	cp -rf ${@:%=/%} $@

${chroot-ln}:
	@mkdir -p `dirname $@` || true
	@./sln $@

items/ users/ home/ .links:
	mkdir -p $@

${chown-dirs}:
	mkdir -p $@
	${sudo} chown ${chown-user}:${chown-group} $@

chroot: ${chroot-cp} ${chroot-ln}

$(mount): dev/ sys/ proc/
	@if ! mount | grep -q "on ${PWD}/$@ type"; then \
		mkdir -p $@ 2>/dev/null || true ; \
		echo ${sudo} mount --bind /$@ $@ ; \
		${sudo} mount --bind /$@ $@ ; \
		fi

clean: modules-clean mounts-clean
	rm -rf ${chroot_mkdir} .all-install .links

mounts-clean:
	test -z "${sorted-mounts}" || \
		${sudo} umount ${sorted-mounts}
	rm -rf ${mounts}

modules-clean:
	-ls items | while read line; do \
		test ! -f items/$$line/Makefile || \
		${MAKE} -C items/$$line clean ; done

etc/resolv.conf: /etc/resolv.conf
	cp /etc/resolv.conf $@

$(mod-y):
	@echo ${MAKEFLAGS}
	${MAKE} module=$@ ${MAKEFLAGS} -f ${PWD}/module.mk ${TARGET}

FORCE:

.PHONY: chroot all mounts-clean \
	modules-clean run srun FORCE mod-dirs mod-bin
