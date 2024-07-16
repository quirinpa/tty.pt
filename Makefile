subdirs := htdocs
uname != uname
unamev != uname -v | awk '{print $$1}'
unamec := ${uname}-${unamev}
mounts-Linux := dev sys proc dev/ptmx dev/pts
mounts := ${mounts-${uname}}
sorted-mounts != echo ${mounts-${uname}} | tr ' ' '\n' | sort
src-y != ls src
DESTDIR := ${PWD}/
PREFIX := usr
INSTALL_DEP := ${PWD}/make_dep.sh
MAKEFLAGS += INSTALL_DEP=${INSTALL_DEP} DESTDIR=${PWD}/
MFLAGS := ${MAKEFLAGS}
mod-y != cat .modules | while read line; do basename $$line | sed s/\\..*//; done
chroot_mkdir := empty bin sessions
sudo-Linux := sudo
sudo-OpenBSD := doas
sudo := ${sudo-${uname}}
LDFLAGS := -L/usr/local/lib
CFLAGS := -I/usr/local/include
lcrypt-Linux := -lcrypt
lcrypt := ${lcrypt-${uname}}

deps := .depend-${unamec}

all:

chroot: chroot_mkdir

${subdirs}:
	@${MAKE} -C $@

${mounts:%=%/}:
	mkdir -p $@

bin/htpasswd: src/htpasswd/htpasswd.c
	${LINK.c} -o $@ src/htpasswd/htpasswd.c -lqhash ${lcrypt}

bin/htmlsh: src/htmlsh/htmlsh.c
	${LINK.c} -o $@ src/htmlsh/htmlsh.c

bin/mpfd: src/mpfd/mpfd.c
	${LINK.c} -o $@ src/mpfd/mpfd.c

src-bin := htpasswd htmlsh mpfd
src-bin := ${src-bin:%=bin/%}

mod-include := ${mod-y:%=items/%/include.mk}
-include ${mod-include}
-include .depend-${unamec}
mod-bin := ${mod-bin:%=bin/%}

all: ${deps} chroot_mkdir chroot ${mounts} ${subdirs} .htpasswd ${mod-bin}
	${sudo} chown www:www sessions

.depend-${unamec}: bin ${src-bin} ${mod-bin}
	echo bin ${src-bin} ${mod-bin}
	@./make_dep.sh

${chroot_cp}:
	cp -rf $^ $@

${chroot_ln}:
	ln -srf $^ $@

${chroot_mkdir}:
	mkdir -p $@

chroot: ${chroot_mkdir} ${chroot_cp} ${chroot_ln}

dev sys proc: dev/ sys/ proc/
	@if ! mount | grep -q "on ${PWD}/$@ type"; then \
		mkdir -p $@ 2>/dev/null || true ; \
		echo ${sudo} mount --bind /$@ $@ ; \
		echo ${sudo} mount --bind /$@ $@ ; \
		fi

dev/pts:
	@if ! mount | grep -q "on ${PWD}/$@ type"; then \
		mkdir -p $@ 2>/dev/null || true ; \
		echo ${sudo} mount -t devpts devpts $@ ; \
		echo ${sudo} mount -t devpts devpts $@ ; \
		fi

dev/ptmx:
	@if test ! -c $@; then \
		cmd="mknod $@ c 5 2 $@ && chmod 666 $@" ; \
		echo ${sudo} sh -c \"$$cmd\" ; \
		echo ${sudo} sh -c \"$$cmd\" ; \
		fi

clean: modules-clean
	test -z "${mounts}" || \
		${sudo} umount ${sorted-mounts} || true
	rm -rf ${chroot_mkdir} ${mounts} .depend-${unamec}

chroot_mkdir: ${chroot_mkdir}

${mod-y:%=items/%/}:
	@cat .modules | grep ${@:items/%/=%}.git | xargs git -C items clone --recursive

modules-clean:
	-ls items | while read line; do \
		test ! -f items/$$line/Makefile || \
		${MAKE} -C items/$$line clean ; done

.htpasswd: bin/htpasswd
	./bin/htpasswd root root >> $@

.PHONY: ${mounts} ${subdirs} chroot chroot_mkdir all \
	modules-clean
