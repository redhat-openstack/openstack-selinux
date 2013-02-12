TARGETS?=openstack-selinux-nova openstack-selinux-quantum swift
MODULES?=${TARGETS:=.pp.bz2}
SHAREDIR?=/usr/share
#INSTALL=?=install

all: ${TARGETS:=.pp.bz2}

%.pp.bz2: %.pp
	@echo Compressing $^ -\> $@
	bzip2 -9 $^

%.pp: %.te
	make -f ${SHAREDIR}/selinux/devel/Makefile $@

clean:
	rm -f *~ *.if *.tc *.pp *.fc *.pp.bz2
	rm -rf tmp

#install:
#	${INSTALL} -m 0644 ${TARGETS} \
#		${DESTDIR}${SHAREDIR}/targeted/modules

