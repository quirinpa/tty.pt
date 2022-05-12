subdirs := htdocs

$(subdirs):
	${MAKE} -C $@

.PHONY: ${subdirs}
