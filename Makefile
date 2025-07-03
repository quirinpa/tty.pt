include common.mk
src-y != ls src
DESTDIR := ${PWD}/
PREFIX := usr
INSTALL_DEP := ${PWD}/make_dep.sh
MAKEFLAGS += INSTALL_DEP=${INSTALL_DEP} DESTDIR=${PWD}/
MFLAGS := ${MAKE}
mod-y != cat .modules | while read line; do basename $$line | sed s/\\..*//; done
mod-dirs := ${mod-y:%=items/%}
chown-user := www
chown-group := www
mounts-Linux := sys proc run/
mounts := ${mounts-${uname}}
chown-dirs-OpenBSD := sessions
chown-dirs := ${chown-dirs-${uname}}
wheel != cat /etc/group | grep -q "^wheel" && echo wheel || echo root
chroot_mkdir := empty sessions etc ${chroot_mkdir-${uname}} tmp tmp/mpfd dev
sudo-Linux := sudo
sudo-OpenBSD := doas
sudo := ${sudo-${uname}}
sudo-root := ${sudo}
LDFLAGS := -L/usr/local/lib
CFLAGS := -g -I/usr/local/include
lcrypt-Linux := -lcrypt
lcrypt := ${lcrypt-${uname}}
all-Linux := etc/shadow
all-OpenBSD := etc/pwd.db
# please change the default if online
shell-OpenBSD := /bin/ksh
shell-Linux := /bin/bash
shell := ${shell-${uname}}
no-shell := /sbin/nologin
npm-root != npm root
npm-lib := @tty-pt/qdb
npm-lib-inc := ${npm-lib:%=node_modules/%/include.mk}
-include $(npm-lib-inc)
npm-bin := ${${npm-lib:%=%-bin}}
npm-rlib := ${${npm-lib:%=%-lib}}
npm-ilib := ${npm-rlib:%=usr/local/lib/%}
prefix := ${npm-lib:%=${npm-root}/%} /usr/local
CFLAGS += ${prefix:%=-I%/include}
LDFLAGS += ${prefix:%=-L%/lib} ${prefix:%=-Wl,-rpath,%/lib}
LINK.bin := ${LINK.c} ${CFLAGS}
qdb := node_modules/@tty-pt/qdb/bin/qdb

all:

chroot: users/ home/

htdocs/vim.css: FORCE
	@${MAKE} -C htdocs/vss

bin/htpasswd: src/htpasswd/htpasswd.c
	@mkdir bin 2>/dev/null || true
	${LINK.bin} -o $@ src/htpasswd/htpasswd.c -lqdb -ldb ${lcrypt} ${LDFLAGS}

bin/htmlsh: src/htmlsh/htmlsh.c
	@mkdir bin 2>/dev/null || true
	${LINK.bin} -o $@ src/htmlsh/htmlsh.c ${LDFLAGS}

bin/urldecode: src/urldecode/urldecode.c
	@mkdir bin 2>/dev/null || true
	${LINK.bin} -o $@ src/urldecode/urldecode.c ${LDFLAGS}

bin/mpfd: src/mpfd/mpfd.c
	@mkdir bin 2>/dev/null || true
	${LINK.bin} -o $@ src/mpfd/mpfd.c ${LDFLAGS}

src-bin := htpasswd htmlsh mpfd urldecode
src-bin := ${src-bin:%=bin/%}

-include .all-install
mod-bin := ${mod-bin:%=bin/%}

mod-bin:
	@echo ${mod-y} | tr ' ' '\n' | while read mod; do \
		${MAKE} -f ${PWD}/module.mk module=$$mod DESTDIR=${PWD}/ ; done

$(npm-lib:%=node_modules/%/include.mk): mod-dirs
	@test -d node_modules || pnpm i
		
mod-dirs:
	@cat .modules | while read line; do \
		dir=`basename $$line | sed 's/\..*//'` ; \
		test ! -d items/$$dir || continue ; \
		git -C items clone --recursive $$line $$dir ; \
		mkdir items/$$dir/items ; \
		done

$(npm-bin:%=usr/local/bin/%): usr/bin/make ${npm-ilib}
	${MAKE} -C node_modules/${npm-${@:usr/local/bin/%=%}}
	${sudo} chroot . ${MAKE} -C node_modules/${npm-${@:usr/local/bin/%=%}} install

$(npm-lib:%=%-bin): ${npm-ilib}
	${MAKE} -C node_modules/${@:%-bin=%}

npm-lib-bin: ${npm-bin:%=usr/local/bin/%}

$(npm-ilib): usr/bin/make
	${MAKE} -C node_modules/${npm-${@:usr/local/lib/%=%}}
	${sudo} chroot . ${MAKE} -C node_modules/${npm-${@:usr/local/lib/%=%}} install

items/index.db:
	paste -d ' ' common-index en-index | \
		./index_put.sh items/index.db
	paste -d ' ' common-index pt-index | \
		./index_put.sh items/index-pt_PT.db

usr/bin/make: .all-install

.all-install: items .links .install
	@cp .install .all-install
	@ls items | while read module; do \
		test ! -f items/$$module/install || cat items/$$module/install; \
		done >> .all-install
	@cp .all-install /tmp/.all-install
	@cat /tmp/.all-install | while read dep ign; do \
		test -f $$dep && echo $$dep || which $$dep 2>/dev/null; \
		done | while read dep; do ./rldd $$dep ; done | sort -u > .all-install

all: .all-install chroot ${npm-lib:%=node_modules/%/include.mk} npm-lib-bin \
	items/index.db htdocs/vim.css  bin/htpasswd etc/passwd etc/group dev/urandom \
	${all-${uname}} ${mounts} etc/group etc/passwd etc/resolv.conf mod-bin ${src-bin}

etc/group:
	echo "${wheel}:*:0:root" > $@
	echo "_shadow:*:65:" >> $@
	echo "www:*:67:root" >> $@
	chmod 644 $@
	${sudo} chown root:${wheel} $@

etc/passwd:
	echo "root:X:0:0:root:/root:${shell}" > $@
	echo "daemon:*:1:1:root:/root:${no-shell}" >> $@
	chmod 644 $@
	${sudo} chown root:${wheel} $@

dev/urandom: ${mounts}
	${MAKE} -f ${PWD}/module.mk module=nd ${MAKEFLAGS} nods

etc/shadow etc/master.passwd:
	@stty -echo
	@echo -n "Please input desired root password: "
	@read PASS && echo "`./bin/htpasswd root $$PASS`:0:0:daemon:0:0:Charlie &:/root:${shell}" > $@
	@stty echo
	@echo "daemon:*:1:1::0:0:The devil will die:/root:/sbin/nologin" >> $@
	@chmod 600 $@
	${sudo} chown root:${wheel} $@

etc/pwd.db: etc/group etc/master.passwd
	${sudo} chroot . pwd_mkdb /etc/master.passwd

${chroot-cp}:
	@mkdir -p `dirname $@` || true
	cp -rf ${@:%=/%} $@

${chroot-ln}:
	@mkdir -p `dirname $@` || true
	@./sln $@

items users/ home/ .links $(chroot_mkdir):
	mkdir -p $@

${chown-dirs}:
	mkdir -p $@
	${sudo} chown ${chown-user}:${chown-group} $@

chroot: ${chroot-cp} ${chroot-ln}

$(mounts): ${chroot_mkdir}
	@if ! mount | grep -q "on ${PWD}/$@ type"; then \
		mkdir -p $@ 2>/dev/null || true ; \
		echo ${sudo} mount --bind /$@ $@ ; \
		${sudo} mount --bind /$@ $@ ; \
		fi

clean: modules-clean mounts-clean
	${sudo} rm -rf ${chroot_mkdir} .all-install .links

mounts-clean:
	test -z "${sorted-mounts}" || ${sudo} umount ${sorted-mounts}
	test -z "${sorted-mounts}" || ${sudo} rm -rf ${mounts}

modules-clean:
	-ls items | while read line; do \
		test ! -f items/$$line/Makefile || \
		${MAKE} -C items/$$line clean ; done

etc/resolv.conf: /etc/resolv.conf
	cp /etc/resolv.conf $@

$(mod-y): all ${chroot_mkdir}
	${MAKE} -f ${PWD}/module.mk module=$@ ${MAKEFLAGS} ${TARGET}

run: all ${chroot_mkdir}
	${MAKE} -f ${PWD}/module.mk module=nd ${MAKEFLAGS} osdbg

module:
	${MAKE} -f ${PWD}/module.mk module=${MODULE} ${MAKEFLAGS} ${TARGET}

FORCE:

.PHONY: chroot all mounts-clean \
	modules-clean run srun FORCE mod-dirs mod-bin
