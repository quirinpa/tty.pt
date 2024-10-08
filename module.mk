-include items/${module}/include.mk
exedir ?= ${exe}
pwd := items/$(module)/src/$(exedir)
bin := ${exe:%=bin/%}

all: ${bin}

$(bin): FORCE
	@${MAKE} -C ${pwd} exe=${@:bin/%=%} DESTDIR=${DESTDIR} \
		-f ${DESTDIR}/include.mk install

FORCE:

mod-bin := $(mod-bin) $(exe)
