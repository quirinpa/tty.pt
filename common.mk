uname != uname
unamev != uname -v | awk '{print $$1}'
unamec := ${uname}-${unamev}
sudo-Linux := sudo
sudo-OpenBSD := doas
sudo := ${sudo-${uname}}
sudo-root := ${sudo}
