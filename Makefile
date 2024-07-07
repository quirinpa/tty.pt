mounts := dev sys proc dev/ptmx dev/pts
subdirs := htdocs
uname != uname
unamev != uname -v | awk '{print $$1}'
uname := ${uname}-${unamev}
src-ls != ls src | while read line; do echo src/$$line; done
INSTALL_DEP := ${PWD}/make_dep.sh
MAKEFLAGS += INSTALL_DEP=${INSTALL_DEP} DESTDIR=${PWD}/
modules != cat .modules | while read line; do basename $$line | sed s/\\..*//; done

all: chroot ${mounts} ${subdirs} ${src-ls} modules
chroot: chroot-dirs

${src-ls}:
	@${MAKE} -C $@ install

${subdirs}:
	@${MAKE} -C $@

${mounts:%=%/}:
	mkdir -p $@

.depend-${uname}:
	./make_dep.sh

include .depend-${uname}

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
		echo sudo mount --bind /$@ $@ ; \
		sudo mount --bind /$@ $@ ; \
		fi

dev/pts:
	@if ! mount | grep -q "on ${PWD}/$@ type"; then \
		mkdir -p $@ 2>/dev/null || true ; \
		echo sudo mount -t devpts devpts $@ ; \
		sudo mount -t devpts devpts $@ ; \
		fi

dev/ptmx:
	@if test ! -c $@; then \
		cmd="mknod $@ c 5 2 $@ && chmod 666 $@" ; \
		echo sudo sh -c \"$$cmd\" ; \
		sudo sh -c \"$$cmd\" ; \
		fi

clean: ${src-ls:src/%=src-%-clean} ${modules:%=items-%-clean}
	sudo umount dev/pts dev/ptmx dev sys proc || true
	sudo rm -rf ${chroot_mkdir} ${mounts}

${src-ls:src/%=src-%-clean}:
	${MAKE} -C ${@:src-%-clean=src/%} clean

modules: ${modules:%=items/%/} ${modules:%=items/%}

${modules:%=items/%/}:
	@cat .modules | grep ${@:items/%/=%}.git | xargs git -C items clone --recursive

${modules:%=items-%-clean}:
	@test ! -d ${@:items-%-clean=items/%}/src || ls ${@:items-%-clean=items/%}/src | while read line; do \
		${MAKE} -C ${@:items-%-clean=items/%}/src/$$line clean; done

${modules:%=items/%}:
	@test ! -d $@/src || ls $@/src | while read line; do \
		${MAKE} -C $@/src/$$line install; done

.PHONY: ${mounts} ${subdirs} ${src-ls} chroot chroot-dirs all modules ${modules:%=items/%} \
	${modules:%=items-%-clean} ${src-ls:src/%=src-%-clean}
