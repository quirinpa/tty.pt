PWD != pwd
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
chroot_mkdir_Linux := ${chown-dirs-OpenBSD}
chroot_mkdir := empty bin ${chroot_mkdir_${uname}}
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

all: ${deps} chroot_mkdir chroot ${mounts} .htpasswd ${mod-bin} ${chown-dirs} htdocs/vim.css

.depend-${unamec}: items/ bin ${src-bin} ${mod-dirs} ${mod-bin}
	@./make_dep.sh
	@ls items | while read line; do \
		test ! -f items/$$line/install \
		|| ./make_dep.sh -C items/$$line; done

${chroot_cp}:
	cp -rf $^ $@

${chroot_ln}:
	ln -srf $^ $@

items/ ${chroot_mkdir}:
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

dev/pts:
	@if ! mount | grep -q "on ${PWD}/$@ type"; then \
		mkdir -p $@ 2>/dev/null || true ; \
		echo ${sudo} mount -t devpts devpts $@ ; \
		${sudo} mount -t devpts devpts $@ ; \
		fi

dev/ptmx:
	@if test ! -c $@; then \
		cmd="mknod $@ c 5 2 $@ && chmod 666 $@" ; \
		echo ${sudo} sh -c \"$$cmd\" ; \
		${sudo} sh -c \"$$cmd\" ; \
		fi

clean: modules-clean
	test -z "${mounts}" || \
		${sudo} umount ${sorted-mounts} || true
	rm -rf ${chroot_mkdir} ${mounts} .depend-${unamec}

chroot_mkdir: ${chroot_mkdir}

$(mod-dirs):
	@cat .modules | grep ${@:items/%/=%}.git | xargs git -C items clone --recursive

modules-clean:
	-ls items | while read line; do \
		test ! -f items/$$line/Makefile || \
		${MAKE} -C items/$$line clean ; done

.htpasswd: bin/htpasswd
	./bin/htpasswd root root >> $@

run: bin/nd
	${sudo-${USER}} ./bin/nd -C ${PWD} -p 8000

srun: bin/nd ss_key.pem ss_cert.pem
	${sudo} ./bin/nd -C ${PWD} -c ss_cert.pem -k ss_key.pem

ss_key.pem:
	openssl genpkey -algorithm RSA -out ss_key.pem -aes256

ss_cert.pem: ss_key.pem
	openssl req -new -key ss_key.pem -out ss_csr.pem
	openssl req -x509 -key ss_key.pem -in ss_csr.pem -out ss_cert.pem -days 365

.PHONY: ${mounts} chroot chroot_mkdir all \
	modules-clean run srun
