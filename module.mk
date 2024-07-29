pwd := items/$(module)/src/$(exe)
$(exe)-path := ${pwd}
source := $(pwd)/$(exe)

$(source): FORCE
	${MAKE} -C `dirname $@`

bin/$(exe): $(pwd)/$(exe)
	@mkdir bin 2>/dev/null || true
	cp ${${@:bin/%=%}-path}/${@:bin/%=%} $@

mod-bin := $(mod-bin) $(exe)
