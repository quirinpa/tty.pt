uname != uname
unamev != uname -v | awk '{print $$1}'
unamec := ${uname}-${unamev}
mounts-Linux := dev sys proc dev/ptmx dev/pts
mounts := ${mounts-${uname}}
sorted-mounts != echo ${mounts-${uname}} | tr ' ' '\n' | sort -r
src-y != ls src
DESTDIR := ${PWD}/
PREFIX := usr
INSTALL_DEP := ${PWD}/make_dep.sh
MAKEFLAGS += INSTALL_DEP=${INSTALL_DEP} DESTDIR=${PWD}/
MFLAGS := ${MAKEFLAGS}
mod-y != cat .modules | while read line; do basename $$line | sed s/\\..*//; done
mod-dirs := ${mod-y:%=items/%/}
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

deps := .depend-${unamec}

all:

chroot: chroot_mkdir

htdocs/vim.css:
	@${MAKE} -C htdocs/vss

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

.depend-${unamec}: ${mod-dirs} ${mod-bin} ${src-bin}
	@./make_dep.sh
	@ls items | while read line; do \
		test ! -f items/$$line/install \
		|| ./make_dep.sh -C items/$$line; done

${mounts:%=%/}:
	mkdir -p $@

bin/: FORCE
	mkdir $@ || true

all: bin/ .depend-${unamec} chroot_mkdir chroot \
	${mounts} .htpasswd

${chroot_cp}:
	cp -rf $^ $@

${chroot_ln}:
	ln -srf $^ $@

items/ ${chroot_mkdir:%=%/}:
	mkdir -p $@

${chown-dirs}:
	mkdir -p $@
	${sudo} chown ${chown-user}:${chown-group} $@

chroot: ${chroot_mkdir} ${chroot_cp} ${chroot_ln}

dev sys proc: dev/ sys/ proc/
	@if ! mount | grep -q "on ${PWD}/$@ type"; then \
		mkdir -p $@ 2>/dev/null || true ; \
		echo ${sudo} mount --bind /$@ $@ ; \
		${sudo} mount --bind /$@ $@ ; \
		fi

clean: modules-clean
	test -z "${sorted-mounts}" || \
		${sudo} umount ${sorted-mounts} || true
	rm -rf ${chroot_mkdir} ${mounts} .depend-${unamec}

chroot_mkdir: ${chroot_mkdir:%=%/}

$(mod-dirs):
	@cat .modules | grep ${@:items/%/=%}.git | xargs git -C items clone --recursive

modules-clean:
	-ls items | while read line; do \
		test ! -f items/$$line/Makefile || \
		${MAKE} -C items/$$line clean ; done

.htpasswd: bin/htpasswd
	./bin/htpasswd root root >> $@

FORCE:

.PHONY: chroot chroot_mkdir all \
	modules-clean run srun FORCE
