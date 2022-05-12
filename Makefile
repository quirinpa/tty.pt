subdirs := htdocs src

all: ${subdirs}

src:
	${MAKE} -C $@ install

${subdirs}:
	${MAKE} -C $@

.PHONY: ${subdirs} all
