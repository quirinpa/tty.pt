#!/bin/sh
mkdir dev 2>/dev/null || true
cd dev
mknod zero c 13 12
mknod null c 13 2
mknod tty c 1 0
chmod 666 zero null tty
cd -
# copy www and root users to etc/master.passwd
# and run the following inside the chroot
# pwd_mkdb /etc/master.passwd
