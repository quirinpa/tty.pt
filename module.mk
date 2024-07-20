pwd := items/$(module)/src/$(exe)
$(exe)-path := ${pwd}
source := $(pwd)/$(exe)

$(source): FORCE
	${MAKE} -C `dirname $@`

bin/$(exe): $(pwd)/$(exe) bin/
	cp ${${@:bin/%=%}-path}/${@:bin/%=%} $@

mod-bin := $(mod-bin) $(exe)
